//
//  CloudKitSettingsManager.swift
//  CostCalculatorApp
//
//  Created by Claude on 2024-07-18.
//

import Foundation
import SwiftUI

class CloudKitSettingsManager: ObservableObject {
    static let shared = CloudKitSettingsManager()
    
    @Published var isCloudKitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudKitEnabled, forKey: "cloudKitEnabled")
            if oldValue != isCloudKitEnabled {
                showRestartAlert = true
            }
        }
    }
    
    @Published var showRestartAlert = false
    
    private init() {
        self.isCloudKitEnabled = UserDefaults.standard.bool(forKey: "cloudKitEnabled")
    }
    
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    var cloudKitStatus: String {
        if !isCloudKitAvailable {
            return "cloudkit_unavailable".localized()
        } else if isCloudKitEnabled {
            return "cloudkit_available".localized()
        } else {
            return "cloudkit_unavailable".localized()
        }
    }
    
    var cloudKitStatusColor: Color {
        if !isCloudKitAvailable {
            return .orange
        } else if isCloudKitEnabled {
            return .green
        } else {
            return .red
        }
    }
    
    func toggleCloudKit() {
        guard isCloudKitAvailable else {
            return
        }
        isCloudKitEnabled.toggle()
    }
}