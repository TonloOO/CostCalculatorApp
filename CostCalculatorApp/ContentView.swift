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
    @State private var auth = AuthManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    /// Statistic tab — exposes machine running status data. Available to admin and manager.
    private var canSeeStatistic: Bool {
        auth.isLoggedIn && (auth.role == "admin" || auth.role == "manager")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("tab_home".localized(), systemImage: "house.circle", value: .home) {
                HomeView()
            }

            Tab("tab_chat".localized(), systemImage: "message.circle", value: .chat) {
                ChatView()
            }

            if canSeeStatistic {
                Tab("tab_statistics".localized(), systemImage: "chart.bar", value: .statistic) {
                    StatisticHomeView()
                }
            }

            Tab("tab_settings".localized(), systemImage: "gearshape", value: .setting) {
                ProfileView()
            }
        }
        .id(languageManager.currentLanguage.rawValue)
        .onChange(of: canSeeStatistic) { _, canSee in
            if !canSee && selectedTab == .statistic {
                selectedTab = .home
            }
        }
    }
}

#Preview {
    ContentView()
}
