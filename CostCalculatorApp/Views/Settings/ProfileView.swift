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

// MARK: - Themed Settings Row

struct ThemedSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
        }
    }
}

struct CloudKitThemedRow: View {
    @Bindable var cloudKitSettings: CloudKitSettingsManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "icloud")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.info)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("data_sync".localized())
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(cloudKitSettings.cloudKitStatusColor)
                            .frame(width: 7, height: 7)
                        Text(cloudKitSettings.cloudKitStatus)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
        }
    }
}

// MARK: - AI Settings View

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var selectedModel: String = ""
    @State private var selectedVisionModel: String = ""
    @State private var showAPIKey = false
    @State private var showModelPicker = false
    @State private var showVisionModelPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.large) {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 48))
                                .foregroundStyle(AppTheme.Colors.primaryGradient)
                            Text("AI 设置")
                                .font(AppTheme.Typography.title2)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            Text("配置 AI 模型 API 服务")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        .padding(.top, AppTheme.Spacing.xxLarge)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("API Base URL")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            TextField("https://api.example.com", text: $baseURL)
                                .font(AppTheme.Typography.body)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.small)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            Divider()

                            Text("API Key")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            HStack {
                                Group {
                                    if showAPIKey {
                                        TextField("sk-...", text: $apiKey)
                                    } else {
                                        SecureField("sk-...", text: $apiKey)
                                    }
                                }
                                .font(AppTheme.Typography.body)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                                Button {
                                    showAPIKey.toggle()
                                } label: {
                                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                }
                            }
                            .padding(AppTheme.Spacing.small)
                            .background(AppTheme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                        .padding(AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, AppTheme.Spacing.large)

                        modelSettingsCard

                        Button {
                            saveSettings()
                            dismiss()
                        } label: {
                            Text("保存设置")
                                .font(AppTheme.Typography.buttonText)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.small)
                                .background(AppTheme.Colors.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        }
                        .padding(.horizontal, AppTheme.Spacing.large)
                    }
                }
            }
            .navigationTitle("AI 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        saveSettings()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            apiKey = KeychainHelper.shared.apiKey
            baseURL = KeychainHelper.shared.baseURL
            selectedModel = KeychainHelper.shared.selectedModel
            selectedVisionModel = KeychainHelper.shared.selectedVisionModel
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet(
                title: "选择对话模型",
                selectedModel: $selectedModel
            )
            .presentationDetents([.fraction(0.75)])
        }
        .sheet(isPresented: $showVisionModelPicker) {
            ModelPickerSheet(
                title: "选择图片识别模型",
                selectedModel: $selectedVisionModel
            )
            .presentationDetents([.fraction(0.75)])
        }
    }

    // MARK: - Model Settings Card

    private var modelSettingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("模型配置")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .padding(.bottom, AppTheme.Spacing.small)

            modelRow(
                icon: "text.bubble",
                label: "对话模型",
                value: selectedModel,
                action: { showModelPicker = true }
            )

            Divider()
                .padding(.leading, 44)

            modelRow(
                icon: "eye.circle",
                label: "图片识别模型",
                value: selectedVisionModel,
                action: { showVisionModelPicker = true }
            )
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, AppTheme.Spacing.large)
    }

    private func modelRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    Text(value)
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty { KeychainHelper.shared.apiKey = trimmedKey }
        if !trimmedURL.isEmpty { KeychainHelper.shared.baseURL = trimmedURL }
        if !selectedModel.isEmpty { KeychainHelper.shared.selectedModel = selectedModel }
        if !selectedVisionModel.isEmpty { KeychainHelper.shared.selectedVisionModel = selectedVisionModel }
    }
}

// MARK: - Model Picker Sheet

struct ModelPickerSheet: View {
    let title: String
    @Binding var selectedModel: String

    @Environment(\.dismiss) private var dismiss
    @State private var models: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText: String = ""

    private var displayModels: [String] {
        if searchText.isEmpty { return models }
        return models.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                        TextField("搜索模型...", text: $searchText)
                            .font(AppTheme.Typography.body)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.small)
                    .background(AppTheme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)

                    if isLoading {
                        Spacer()
                        ProgressView("正在获取模型列表...")
                            .font(AppTheme.Typography.subheadline)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.medium) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.Colors.warning)
                            Text(error)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                            Button("重试") { fetchModels() }
                                .font(AppTheme.Typography.buttonText)
                                .foregroundStyle(AppTheme.Colors.primary)
                        }
                        .padding()
                        Spacer()
                    } else if displayModels.isEmpty && !models.isEmpty {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.Colors.tertiaryText)
                            Text("未找到匹配的模型")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(displayModels, id: \.self) { model in
                                Button {
                                    selectedModel = model
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(model)
                                            .font(AppTheme.Typography.body)
                                            .foregroundStyle(AppTheme.Colors.primaryText)

                                        Spacer()

                                        if model == selectedModel {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(AppTheme.Colors.primary)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .listRowBackground(
                                    model == selectedModel
                                    ? AppTheme.Colors.primary.opacity(0.06)
                                    : AppTheme.Colors.background
                                )
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        fetchModels()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(isLoading)
                    .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            fetchModels()
        }
    }

    private func fetchModels() {
        isLoading = true
        errorMessage = nil
        Task { @MainActor in
            defer { isLoading = false }
            do {
                models = try await LLMChatService.shared.fetchModels()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preserved Sub-Views

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
                        } else {
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
}

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

#Preview {
    ProfileView()
}
