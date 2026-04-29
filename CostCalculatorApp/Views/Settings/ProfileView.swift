import SwiftUI

struct ProfileView: View {
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingCloudKitSettings = false
    @State private var showingLanguageSettings = false
    @State private var showingAISettings = false
    @State private var languageChanged = false
    @State private var cloudKitSettings = CloudKitSettingsManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        headerSection
                        aiSettingsCard
                        appSettingsCard
                        aboutCard
                        versionInfo
                    }
                    .padding(.bottom, 100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .id(languageManager.currentLanguage.rawValue)
        .sheet(isPresented: $showingSettings) { AppSettingsView() }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .sheet(isPresented: $showingCloudKitSettings) { CloudKitSettingsView() }
        .sheet(isPresented: $showingLanguageSettings) { LanguageSettingsView() }
        .sheet(isPresented: $showingAISettings) { AISettingsView() }
        .alert("restart_required".localized(), isPresented: $cloudKitSettings.showRestartAlert) {
            Button("ok".localized()) { cloudKitSettings.showRestartAlert = false }
        } message: {
            Text("icloud_note3".localized())
        }
        .alert("restart_required".localized(), isPresented: $languageManager.showRestartAlert) {
            Button("ok".localized()) { languageManager.showRestartAlert = false }
        } message: {
            Text("restart_message".localized())
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text("settings".localized())
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("管理应用与 AI 配置")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)
    }

    // MARK: - AI Settings Card

    private var aiSettingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "brain.head.profile", title: "AI 设置")

            ThemedSettingsRow(
                icon: "key.fill",
                iconColor: AppTheme.Colors.warning,
                title: "API 配置",
                subtitle: maskedAPIKey,
                action: { showingAISettings = true }
            )
        }
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, AppTheme.Spacing.large)
    }

    private var maskedAPIKey: String {
        let key = KeychainHelper.shared.apiKey
        if key.count > 8 {
            return String(key.prefix(6)) + "..." + String(key.suffix(4))
        }
        return "未配置"
    }

    // MARK: - App Settings Card

    private var appSettingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "wrench.and.screwdriver", title: "应用设置")

            ThemedSettingsRow(
                icon: "globe",
                iconColor: AppTheme.Colors.info,
                title: "language_settings".localized(),
                subtitle: "language_subtitle".localized(),
                action: { showingLanguageSettings = true }
            )
            Divider().padding(.leading, 56)
            CloudKitThemedRow(
                cloudKitSettings: cloudKitSettings,
                action: { showingCloudKitSettings = true }
            )
        }
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, AppTheme.Spacing.large)
    }

    // MARK: - About Card

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "info.circle", title: "关于")

            ThemedSettingsRow(
                icon: "questionmark.circle",
                iconColor: AppTheme.Colors.secondary,
                title: "about_app".localized(),
                subtitle: "about_app_subtitle".localized(),
                action: { showingAbout = true }
            )
            Divider().padding(.leading, 56)
            ThemedSettingsRow(
                icon: "envelope",
                iconColor: AppTheme.Colors.success,
                title: "feedback".localized(),
                subtitle: "feedback_subtitle".localized(),
                action: {}
            )
        }
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, AppTheme.Spacing.large)
    }

    // MARK: - Section Header Helper

    private func settingsSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primary)
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.small)
    }

    // MARK: - Version

    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("cost_calculator".localized())
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
            Text("version".localized())
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.tertiaryText.opacity(0.7))
        }
        .padding(.top, AppTheme.Spacing.medium)
    }
}

#Preview {
    ProfileView()
}
