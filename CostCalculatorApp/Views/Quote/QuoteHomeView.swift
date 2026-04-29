//
//  QuoteHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct QuoteHomeView: View {
    @State private var apiService = QuoteAPIService.shared
    @State private var authManager = QuoteAuthManager.shared
    @State private var isServerOnline = false
    @State private var showSettings = false
    @State private var showCreateQuote = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            quoteHeader
            connectionStatusBar
            QuoteOverviewView()
        }
        .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            APISettingsView()
        }
        .sheet(isPresented: $showCreateQuote) {
            QuoteCreateView()
        }
        .task {
            isServerOnline = await apiService.healthCheck()
        }
    }
    
    private var quoteHeader: some View {
        customNavHeader(
            title: "报价查询",
            backLabel: "首页",
            dismiss: dismiss,
            trailing: {
                HStack(spacing: AppTheme.Spacing.medium) {
                    Button(action: { showCreateQuote = true }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                    }

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                    }

                    Button(action: { authManager.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                    }
                }
            }
        )
        .padding(.bottom, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.groupedBackground)
    }
    
    private var connectionStatusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isServerOnline ? AppTheme.Colors.success : AppTheme.Colors.error)
                .frame(width: 8, height: 8)
            
            Text(isServerOnline ? "服务器已连接" : "服务器未连接")
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(isServerOnline ? AppTheme.Colors.success : AppTheme.Colors.error)
            
            Spacer()
            
            Text(apiService.baseURL)
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(
            (isServerOnline ? AppTheme.Colors.success : AppTheme.Colors.error)
                .opacity(0.08)
        )
    }

}

// MARK: - API Settings

struct APISettingsView: View {
    @State private var apiService = QuoteAPIService.shared
    @State private var urlInput = ""
    @State private var testResult: Bool?
    @State private var isTesting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API 服务器地址")) {
                    TextField("http://192.168.1.100:8000", text: $urlInput)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("模拟器可使用 localhost，真机需使用局域网 IP")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("测试连接")
                        }
                    }
                    .disabled(isTesting || urlInput.isEmpty)
                    
                    if let result = testResult {
                        HStack {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result ? AppTheme.Colors.success : AppTheme.Colors.error)
                            Text(result ? "连接成功" : "连接失败")
                                .foregroundStyle(result ? AppTheme.Colors.success : AppTheme.Colors.error)
                        }
                    }
                }
                
                Section {
                    Button(action: saveAndDismiss) {
                        Text("保存")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(urlInput.isEmpty)
                }
            }
            .navigationTitle("API 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                urlInput = apiService.baseURL
            }
        }
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        let savedURL = apiService.baseURL
        apiService.baseURL = urlInput
        
        Task {
            let result = await apiService.healthCheck()
            await MainActor.run {
                testResult = result
                isTesting = false
                if !result {
                    apiService.baseURL = savedURL
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        apiService.baseURL = urlInput
        dismiss()
    }
}
