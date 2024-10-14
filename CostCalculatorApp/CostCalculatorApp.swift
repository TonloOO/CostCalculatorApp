//
//  CostCalculatorAppApp.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI

@main
struct CostCalculatorApp: App {
    @StateObject private var calculationHistory = CalculationHistory()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calculationHistory)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                calculationHistory.saveHistory()
            }
        }
    }
    
    @Environment(\.scenePhase) var scenePhase
}


