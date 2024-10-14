//
//  UserManager.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-06.
//


import Foundation

class UserManager {
    static let shared = UserManager()
    
    private let userIDKey = "userIDKey"
    
    var userID: String {
        if let storedUserID = UserDefaults.standard.string(forKey: userIDKey) {
            return storedUserID
        } else {
            let newUserID = UUID().uuidString
            UserDefaults.standard.set(newUserID, forKey: userIDKey)
            return newUserID
        }
    }
}
