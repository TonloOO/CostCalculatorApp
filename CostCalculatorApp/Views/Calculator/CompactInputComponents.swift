//
//  CompactInputComponents.swift
//  CostCalculatorApp
//
//  Created by AI Assistant on 2024-12-20.
//

import SwiftUI

// MARK: - Compact Input Field for Two Items in a Row
struct CompactInputRow: View {
    let leftField: InputFieldConfig
    let rightField: InputFieldConfig
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            CompactInputField(config: leftField)
            CompactInputField(config: rightField)
        }
    }
}

// MARK: - Single Compact Input Field
struct CompactInputField: View {
    let config: InputFieldConfig
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(config.label)
                .font(.system(size: 15))
                .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                .animation(AppTheme.Animation.quick, value: isFocused)
            
            HStack(spacing: 4) {
                if let icon = config.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                        .frame(width: 20)
                }
                
                TextField("", text: config.text)
                    .keyboardType(config.keyboardType)
                    .focused($isFocused)
                    .font(.system(size: 15))
                
                if !config.suffix.isEmpty {
                    Text(config.suffix)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText.opacity(0.2),
                        lineWidth: isFocused ? 1.5 : 1
                    )
                    .animation(AppTheme.Animation.quick, value: isFocused)
            )
        }
    }
}

// MARK: - Input Field Configuration
struct InputFieldConfig {
    let label: String
    let text: Binding<String>
    let suffix: String
    let keyboardType: UIKeyboardType
    let icon: String?
    
    init(label: String, text: Binding<String>, suffix: String = "", keyboardType: UIKeyboardType = .decimalPad, icon: String? = nil) {
        self.label = label
        self.text = text
        self.suffix = suffix
        self.keyboardType = keyboardType
        self.icon = icon
    }
}

// MARK: - Compact Section Header
struct CompactSectionHeader: View {
    let title: String
    var icon: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
                .textCase(.uppercase)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Yarn Input Field
struct CompactYarnInputField: View {
    @Binding var yarnValue: String
    @Binding var yarnTypeSelection: YarnType
    var label: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label)规格")
                .font(.system(size: 14))
                .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
            
            HStack(spacing: 4) {
                TextField("", text: $yarnValue)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
                
                Menu {
                    Button("D数") { yarnTypeSelection = .dNumber }
                    Button("支数") { yarnTypeSelection = .yarnCount }
                } label: {
                    HStack(spacing: 2) {
                        Text(yarnTypeSelection.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.primaryText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText.opacity(0.2),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
        }
    }
}

// MARK: - Compact Card Container
struct CompactCard<Content: View>: View {
    let title: String?
    var icon: String? = nil
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if let title = title {
                CompactSectionHeader(title: title, icon: icon)
            }
            
            content
                .padding(.horizontal, 4)
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.secondaryBackground)
        )
    }
}
