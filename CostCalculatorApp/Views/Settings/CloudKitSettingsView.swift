//
//  CloudKitSettingsView.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

struct CloudKitSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cloudKitSettings = CloudKitSettingsManager.shared
    @State private var languageChanged = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "icloud")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.primaryGradient)

                        Text("icloud_sync".localized())
                            .font(AppTheme.Typography.title2)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(cloudKitSettings.cloudKitStatusColor)
                                .frame(width: 10, height: 10)
                            Text(cloudKitSettings.cloudKitStatus)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(cloudKitSettings.cloudKitStatusColor)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xxxLarge)
                    .padding(.bottom, AppTheme.Spacing.xxLarge)

                    VStack(spacing: 0) {
                        if cloudKitSettings.isCloudKitAvailable {
                            availableSection
                        } else {
                            unavailableSection
                        }
                    }
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                    .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppTheme.Spacing.large)

                    Spacer()
                }
            }
            .navigationTitle("data_sync".localized())
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

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("enable_icloud".localized())
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                    Text("icloud_description".localized())
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                Spacer()
                Toggle("", isOn: $cloudKitSettings.isCloudKitEnabled)
                    .labelsHidden()
                    .tint(AppTheme.Colors.primary)
            }

            Divider()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("explanation".localized())
                    .font(AppTheme.Typography.footnote)
                    .fontWeight(.medium)
                Text("icloud_note1".localized())
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Text("icloud_note2".localized())
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Text("icloud_note3".localized())
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.warning)
            }
        }
        .padding(AppTheme.Spacing.medium)
    }

    private var unavailableSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.Colors.warning)
            Text("icloud_unavailable".localized())
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.warning)
            Text("icloud_login_required".localized())
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            Button("open_settings".localized()) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundStyle(AppTheme.Colors.primary)
        }
        .padding(AppTheme.Spacing.medium)
    }
}
