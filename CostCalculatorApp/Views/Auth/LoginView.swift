//
//  LoginView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct LoginView: View {
    /// When true, the view dismisses itself on successful login (used by ProfileView's
    /// "登录账号" row). When false, the caller is expected to observe `AuthManager.isLoggedIn`
    /// and swap content (used by HomeView's report card flow).
    var dismissOnSuccess: Bool = false

    @State private var authManager = AuthManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isShaking = false
    @State private var showSecretSheet = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    enum Field { case username, password }

    private var hasSecret: Bool {
        guard let s = authManager.appSecret else { return false }
        return !s.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxLarge) {
                    Spacer().frame(height: 40)

                    lockIcon
                    titleSection
                    loginForm
                    loginButton

                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.xLarge)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("登录验证")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSecretSheet = true
                } label: {
                    Image(systemName: hasSecret ? "key.fill" : "key")
                        .foregroundStyle(hasSecret ? AppTheme.Colors.primary : AppTheme.Colors.error)
                }
            }
        }
        .sheet(isPresented: $showSecretSheet) {
            AppSecretSettingView()
        }
        .onAppear {
            if !hasSecret {
                showSecretSheet = true
            }
        }
    }

    // MARK: - Lock Icon

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primaryGradient)
                .frame(width: 80, height: 80)

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white)
        }
        .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Text("ERP 登录")
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("请使用企业账号登录")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    // MARK: - Form

    private var loginForm: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("用户名")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                HStack {
                    Image(systemName: "person")
                        .font(.system(size: 16))
                        .foregroundStyle(focusedField == .username ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)

                    TextField("请输入用户名", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.secondaryBackground)
                .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(focusedField == .username ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("密码")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                HStack {
                    Image(systemName: "lock")
                        .font(.system(size: 16))
                        .foregroundStyle(focusedField == .password ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)

                    SecureField("请输入密码", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.secondaryBackground)
                .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(focusedField == .password ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                )
            }

            if !hasSecret {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text("请先点击右上角设置应用密钥")
                        .font(AppTheme.Typography.footnote)
                }
                .foregroundStyle(AppTheme.Colors.warning)
            }

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(error)
                        .font(AppTheme.Typography.footnote)
                }
                .foregroundStyle(AppTheme.Colors.error)
                .offset(x: isShaking ? -8 : 0)
                .animation(
                    .default.repeatCount(3, autoreverses: true).speed(6),
                    value: isShaking
                )
            }
        }
    }

    // MARK: - Button

    private var loginButton: some View {
        Button(action: performLogin) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                }
                Text(authManager.isLoading ? "登录中..." : "登录")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                (username.isEmpty || password.isEmpty || !hasSecret || authManager.isLoading)
                    ? AnyShapeStyle(Color.gray.opacity(0.4))
                    : AnyShapeStyle(AppTheme.Colors.primaryGradient)
            )
            .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .disabled(username.isEmpty || password.isEmpty || !hasSecret || authManager.isLoading)
    }

    // MARK: - Action

    private func performLogin() {
        focusedField = nil
        errorMessage = nil
        authManager.isLoading = true

        Task {
            let result = await authManager.login(username: username, password: password)
            await MainActor.run {
                authManager.isLoading = false
                switch result {
                case .success:
                    HapticFeedbackManager.shared.notification(type: .success)
                    if dismissOnSuccess {
                        dismiss()
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    HapticFeedbackManager.shared.notification(type: .error)
                    isShaking.toggle()
                }
            }
        }
    }
}
