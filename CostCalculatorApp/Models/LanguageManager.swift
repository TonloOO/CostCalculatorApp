//
//  LanguageManager.swift
//  CostCalculatorApp
//
//  Created by Claude on 2024-07-21.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            Bundle.setLanguage(currentLanguage.rawValue)
            // Force immediate UI update
            self.objectWillChange.send()
            // Post notification for additional components
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
            }
        }
    }
    
    @Published var showRestartAlert = false
    @Published var refreshUI = false
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to Chinese
            self.currentLanguage = .chinese
            UserDefaults.standard.set(AppLanguage.chinese.rawValue, forKey: "AppLanguage")
        }
        
        // Set the app language
        Bundle.setLanguage(currentLanguage.rawValue)
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        Bundle.setLanguage(language.rawValue)
        
        // Force immediate UI refresh
        DispatchQueue.main.async {
            self.refreshUI.toggle()
            self.objectWillChange.send()
        }
    }
}

extension Bundle {
    private static var bundle: Bundle!
    
    public static func localizedBundle() -> Bundle! {
        let appLang = UserDefaults.standard.string(forKey: "AppLanguage") ?? "zh-Hans"
        if let path = Bundle.main.path(forResource: appLang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
    
    public static func setLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        bundle = nil // Reset bundle to force reload
    }
}

extension String {
    func localized() -> String {
        return Bundle.localizedBundle().localizedString(forKey: self, value: self, table: nil)
    }
}