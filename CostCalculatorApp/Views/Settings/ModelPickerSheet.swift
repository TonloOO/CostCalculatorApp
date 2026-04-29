//
//  ModelPickerSheet.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

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
