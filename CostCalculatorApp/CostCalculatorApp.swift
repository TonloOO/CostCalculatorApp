//
//  CostCalculatorApp.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI
import CoreData

@main
struct CostCalculatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}



