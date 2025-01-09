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

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init() {
        container = NSPersistentCloudKitContainer(name: "Model") // Use your data model name

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store descriptions found.")
        }

        // Enable CloudKit integration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.ton.CostCalculatorApp") // Replace with your container identifier

        // Set up remote change notifications
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Load persistent stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
