//
//  PersistenceController.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-15.
//


//
//  PersistenceController.swift
//  CostCalculatorApp
//

import CoreData
import os.log

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    private let logger = Logger(subsystem: "com.zishuoli.CostCalculatorApp", category: "PersistenceController")
    private let cloudKitEnabledKey = "cloudKitEnabled"

    let container: NSPersistentCloudKitContainer
    @Published private(set) var isCloudKitEnabled: Bool = false
    private(set) var initializationError: Error?
    
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private init() {
        container = NSPersistentCloudKitContainer(name: "Model")
        
        // Load CloudKit preference from UserDefaults
        let savedPreference = UserDefaults.standard.bool(forKey: cloudKitEnabledKey)
        
        if let description = container.persistentStoreDescriptions.first {
            // Configure CloudKit integration based on user preference and availability
            if savedPreference && isCloudKitAvailable {
                setupCloudKitIntegration(for: description)
            } else {
                setupLocalOnlyStorage(for: description)
            }
            
            // Set up remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Enable persistent history tracking (required for CloudKit)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Configure merge policy for better conflict resolution
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true

            // Load persistent stores with proper error handling
            loadPersistentStores()
        } else {
            let error = PersistenceError.noStoreDescriptionsFound
            logger.error("Initialization failed: \(error.localizedDescription)")
            initializationError = error
        }
    }
    
    // MARK: - Private Setup Methods
    private func setupCloudKitIntegration(for description: NSPersistentStoreDescription) {
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.ton.CostCalculatorApp"
        )
        isCloudKitEnabled = true
        logger.info("CloudKit integration enabled")
    }
    
    private func setupLocalOnlyStorage(for description: NSPersistentStoreDescription) {
        description.cloudKitContainerOptions = nil
        isCloudKitEnabled = false
        logger.info("Local-only storage configured")
    }
    
    private func loadPersistentStores() {
        let group = DispatchGroup()
        var loadError: Error?
        
        group.enter()
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            defer { group.leave() }
            
            if let error = error as NSError? {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                loadError = error
                
                // Attempt recovery
                if let self = self {
                    if let recoveryError = self.attemptStoreRecovery(storeDescription: storeDescription) {
                        self.logger.error("Store recovery failed: \(recoveryError.localizedDescription)")
                        loadError = recoveryError
                    }
                }
            } else {
                self?.logger.info("Successfully loaded persistent store")
            }
        }
        
        group.wait()
        
        if let error = loadError {
            initializationError = error
        }
    }
    
    private func attemptStoreRecovery(storeDescription: NSPersistentStoreDescription) -> Error? {
        logger.info("Attempting store recovery by disabling CloudKit...")
        
        // Remove CloudKit options and mark as disabled
        storeDescription.cloudKitContainerOptions = nil
        isCloudKitEnabled = false
        
        logger.info("Store recovery completed - CloudKit disabled, using local storage")
        return nil
    }
    
    // MARK: - CloudKit Management
    func enableCloudKit() {
        guard isCloudKitAvailable else {
            logger.warning("CloudKit is not available on this device")
            return
        }
        
        UserDefaults.standard.set(true, forKey: cloudKitEnabledKey)
        logger.info("CloudKit enabled - restart required to take effect")
    }
    
    func disableCloudKit() {
        UserDefaults.standard.set(false, forKey: cloudKitEnabledKey)
        logger.info("CloudKit disabled - restart required to take effect")
    }
    
    func toggleCloudKit() {
        let newValue = !UserDefaults.standard.bool(forKey: cloudKitEnabledKey)
        UserDefaults.standard.set(newValue, forKey: cloudKitEnabledKey)
        logger.info("CloudKit toggled to \(newValue ? "enabled" : "disabled") - restart required to take effect")
    }
    
    var cloudKitSetting: Bool {
        get {
            UserDefaults.standard.bool(forKey: cloudKitEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cloudKitEnabledKey)
        }
    }
    
    // MARK: - Public Methods
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
            logger.info("Context saved successfully")
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            throw PersistenceError.saveContextFailed(error)
        }
    }
    
    func backgroundSave() {
        container.performBackgroundTask { context in
            do {
                try context.save()
                self.logger.info("Background context saved successfully")
            } catch {
                self.logger.error("Failed to save background context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Types
    enum PersistenceError: LocalizedError {
        case noStoreDescriptionsFound
        case storeRecoveryFailed(Error)
        case saveContextFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .noStoreDescriptionsFound:
                return "没有找到持久化存储描述。"
            case .storeRecoveryFailed(let error):
                return "存储恢复失败: \(error.localizedDescription)"
            case .saveContextFailed(let error):
                return "保存上下文失败: \(error.localizedDescription)"
            }
        }
    }
}
