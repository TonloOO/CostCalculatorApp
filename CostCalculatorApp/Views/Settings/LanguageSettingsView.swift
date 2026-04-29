//
//  LanguageSettingsView.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "globe")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                        Text("language_settings".localized())
                            .font(AppTheme.Typography.title2)
                        Text("language_subtitle".localized())
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.Spacing.xxxLarge)
                    .padding(.bottom, AppTheme.Spacing.xxLarge)

                    VStack(spacing: 0) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            HStack {
                                Text(language.displayName)
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.Colors.primaryText)
                                Spacer()
                                if languageManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.primary)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .contentShape(Rectangle())
                            .onTapGesture { languageManager.setLanguage(language) }

                            if language != AppLanguage.allCases.last {
                                Divider().padding(.leading, AppTheme.Spacing.medium)
                            }
                        }
                    }
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                    .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppTheme.Spacing.large)

                    Spacer()
                }
            }
            .navigationTitle("language".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("back".localized()) { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .id(languageManager.currentLanguage.rawValue)
    }
}
