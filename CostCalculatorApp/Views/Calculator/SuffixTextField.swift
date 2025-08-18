//
//  SuffixTextField.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct SuffixTextField: View {
    var label: String
    @Binding var text: String
    var suffix: String
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                .animation(AppTheme.Animation.quick, value: isFocused)
            
            HStack(spacing: AppTheme.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                        .frame(width: 24)
                }
                
                TextField("", text: $text)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
                    .font(AppTheme.Typography.body)
                    .onChange(of: isFocused) { focused in
                        if focused {
                            HapticFeedbackManager.shared.selectionChanged()
                        }
                    }
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(
                        isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText.opacity(0.2),
                        lineWidth: isFocused ? 2 : 1
                    )
                    .animation(AppTheme.Animation.quick, value: isFocused)
            )
        }
    }
}

