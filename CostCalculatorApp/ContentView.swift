//
//  ContentView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "house.circle"
    case chat = "message"
    case statistic = "chart.bar"
    case setting = "gear"
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        VStack {
            // Main content area
            ZStack {
                switch selectedTab {
                case .home:
                    CalculationHomeView()
                case .chat:
                    ChatView()
                case .statistic:
                    StatisticHomeView()
                case .setting:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom bottom navigation bar
            BottomNavigationBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
        .id(languageManager.currentLanguage.rawValue)
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: Tab
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    VStack {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        Text(tabLabel(for: tab))
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(Capsule())
        .shadow(radius: 10)
        .id(languageManager.currentLanguage.rawValue)
    }
    
    private func tabLabel(for tab: Tab) -> String {
        switch tab {
        case .home: return "tab_home".localized()
        case .chat: return "tab_chat".localized()
        case .statistic: return "tab_statistics".localized()
        case .setting: return "tab_settings".localized()
        }
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


