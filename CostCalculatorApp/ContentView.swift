//
//  ContentView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var calculationHistory: CalculationHistory

    var body: some View {
        TabView {
            CalculationHomeView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("费用计算")
                }

            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("织梦·雅集")
                }
        }
    }
}


