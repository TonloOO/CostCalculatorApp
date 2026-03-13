//
//  QuoteLoginView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct QuoteLoginView: View {
    @StateObject private var authManager = QuoteAuthManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var appSecret: String
    @State private var errorMessage: String?
    @State private var isShaking = false
    @FocusState private var focusedField: Field?
    
    enum Field { case username, password, secret }
    
    init() {
        _appSecret = State(initialValue: QuoteAuthManager.shared.appSecret ?? "")
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
    }
    
    // MARK: - Lock Icon
    
    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primaryGradient)
                .frame(width: 80, height: 80)
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
        }
        .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Text("报价审批系统")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Text("请使用企业账号登录")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
    
    // MARK: - Form
    
    private var loginForm: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("用户名")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                HStack {
                    Image(systemName: "person")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .username ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                    
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
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(focusedField == .username ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                )
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("密码")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                HStack {
                    Image(systemName: "lock")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .password ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                    
                    SecureField("请输入密码", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .secret }
                }
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(focusedField == .password ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("应用密钥")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .secret ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                    
                    SecureField("请输入应用密钥", text: $appSecret)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .secret)
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(focusedField == .secret ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                )
                
                Text("首次输入后将自动保存，无需重复输入")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(error)
                        .font(AppTheme.Typography.footnote)
                }
                .foregroundColor(AppTheme.Colors.error)
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                (username.isEmpty || password.isEmpty || appSecret.isEmpty || authManager.isLoading)
                    ? AnyShapeStyle(Color.gray.opacity(0.4))
                    : AnyShapeStyle(AppTheme.Colors.primaryGradient)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .disabled(username.isEmpty || password.isEmpty || appSecret.isEmpty || authManager.isLoading)
    }
    
    // MARK: - Action
    
    private func performLogin() {
        focusedField = nil
        errorMessage = nil
        authManager.isLoading = true
        
        Task {
            let result = await authManager.login(username: username, password: password, secret: appSecret)
            await MainActor.run {
                authManager.isLoading = false
                switch result {
                case .success:
                    HapticFeedbackManager.shared.notification(type: .success)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    HapticFeedbackManager.shared.notification(type: .error)
                    isShaking.toggle()
                }
            }
        }
    }
}
