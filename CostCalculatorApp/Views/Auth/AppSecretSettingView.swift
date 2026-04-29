//
//  AppSecretSettingView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct AppSecretSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var secret: String
    @State private var saved = false

    init() {
        _secret = State(initialValue: AuthManager.shared.appSecret ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("请输入 32 位应用密钥", text: $secret)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("应用密钥")
                } footer: {
                    Text("此密钥由管理员提供，用于验证应用的合法性。设置后将安全保存，无需重复输入。")
                }

                if saved {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("密钥已保存")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("密钥设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        AuthManager.shared.saveAppSecret(secret)
                        saved = true
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(600))
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
