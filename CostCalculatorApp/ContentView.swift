//
//  ContentView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-24.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case chat
    case statistic
    case setting
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("tab_home".localized(), systemImage: "house.circle", value: .home) {
                HomeView()
            }

            Tab("tab_chat".localized(), systemImage: "message.circle", value: .chat) {
                ChatView()
            }

            Tab("tab_statistics".localized(), systemImage: "chart.bar", value: .statistic) {
                StatisticHomeView()
            }

            Tab("tab_settings".localized(), systemImage: "gearshape", value: .setting) {
                ProfileView()
            }
        }
        .id(languageManager.currentLanguage.rawValue)
    }
}

#Preview {
    ContentView()
}
