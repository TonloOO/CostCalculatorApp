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
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: Tab
    
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
    }
    
    private func tabLabel(for tab: Tab) -> String {
        switch tab {
        case .home: return "费用计算"
        case .chat: return "织梦·雅集"
        case .statistic: return "统计"
        case .setting: return "设置"
        }
    }
}



struct ProfileView: View {
    var body: some View {
        Text("设置")
            .font(.largeTitle)
            .foregroundColor(.gray)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


