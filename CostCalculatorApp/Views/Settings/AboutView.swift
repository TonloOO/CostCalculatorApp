//
//  AboutView.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageChanged = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.large) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.primaryGradient)

                    Text("cost_calculator".localized())
                        .font(AppTheme.Typography.title1)

                    Text("version".localized())
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("features".localized())
                            .font(AppTheme.Typography.headline)
                        Text("feature_cost_calculation".localized())
                        Text("feature_multi_material".localized())
                        Text("feature_cloud_sync".localized())
                        Text("feature_history".localized())
                    }
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .padding(.horizontal, AppTheme.Spacing.large)

                    Spacer()

                    Text("copyright".localized())
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
                .padding(.top, AppTheme.Spacing.xxLarge)
            }
            .navigationTitle("about".localized())
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
