//
//  AppSettingsView.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageChanged = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("app_settings".localized())
                    .font(AppTheme.Typography.title2)
                    .padding()
                Text("settings_under_development".localized())
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Spacer()
            }
            .background(AppTheme.Colors.groupedBackground)
            .navigationTitle("settings".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized()) { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .id(LanguageManager.shared.currentLanguage.rawValue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }
}
