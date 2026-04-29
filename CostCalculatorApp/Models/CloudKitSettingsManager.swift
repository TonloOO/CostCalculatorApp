//
//  CloudKitSettingsManager.swift
//  CostCalculatorApp
//
//  Created by Claude on 2024-07-18.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class CloudKitSettingsManager {
    static let shared = CloudKitSettingsManager()

    var isCloudKitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudKitEnabled, forKey: "cloudKitEnabled")
            if oldValue != isCloudKitEnabled {
                showRestartAlert = true
            }
        }
    }

    var showRestartAlert = false

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