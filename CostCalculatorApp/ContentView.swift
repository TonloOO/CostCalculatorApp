//
//  ContentView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "house.circle"
    case chat = "message.circle"
    case statistic = "chart.bar"
    case setting = "gearshape"
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.Colors.background, AppTheme.Colors.secondaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content area
            TabView(selection: $selectedTab) {
                CalculationHomeView()
                    .tag(Tab.home)
                
                ChatView()
                    .tag(Tab.chat)
                
                StatisticHomeView()
                    .tag(Tab.statistic)
                
                ProfileView()
                    .tag(Tab.setting)
            }
            
            // Custom bottom navigation bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .id(languageManager.currentLanguage.rawValue)
    }
}

// Legacy BottomNavigationBar - replaced with CustomTabBar from CustomComponents






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


