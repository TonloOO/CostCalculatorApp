//
//  AISettingsView.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

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
