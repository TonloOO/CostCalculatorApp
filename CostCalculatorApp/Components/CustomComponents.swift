//
//  CustomComponents.swift
//  CostCalculatorApp
//
//  Created by AI Assistant on 2024-12-20.
//

import SwiftUI

// MARK: - Custom Navigation Bar
struct CustomNavigationBar: View {
    let title: String
    var leftAction: (() -> Void)?
    var rightAction: (() -> Void)?
    var leftIcon: String = "arrow.left"
    var rightIcon: String = "ellipsis"
    
    var body: some View {
        HStack {
            if let leftAction = leftAction {
                Button(action: leftAction) {
                    Image(systemName: leftIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primaryText)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Spacer()
            
            if let rightAction = rightAction {
                Button(action: rightAction) {
                    Image(systemName: rightIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primaryText)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(AppTheme.Spacing.large)
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(gradient)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(AppTheme.Animation.standard) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea(edges: .bottom)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
        )
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .offset(y: 10)
    }
}

struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.selectionChanged()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.rawValue)
                    .font(.system(size: 24))
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tabLabel(for: tab))
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func tabLabel(for tab: Tab) -> String {
        switch tab {
        case .home: return "tab_home".localized()
        case .chat: return "tab_chat".localized()
        case .statistic: return "tab_statistics".localized()
        case .setting: return "tab_settings".localized()
        }
    }
}

// MARK: - Modern Input Field
struct ModernInputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var suffix: String = ""
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                }
                
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
                    .font(AppTheme.Typography.body)
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isFocused ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .animation(AppTheme.Animation.quick, value: isFocused)
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isHighlighted ? AppTheme.Colors.accent : AppTheme.Colors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(value)
                    .font(isHighlighted ? AppTheme.Typography.title3 : AppTheme.Typography.headline)
                    .foregroundColor(isHighlighted ? AppTheme.Colors.accent : AppTheme.Colors.primaryText)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            isHighlighted ? 
            AppTheme.Colors.accent.opacity(0.1) : 
            AppTheme.Colors.secondaryBackground
        )
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.tertiaryText)
            
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .primaryButton()
                }
            }
        }
        .padding(AppTheme.Spacing.xxLarge)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .padding(AppTheme.Spacing.xxLarge)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Colors.shadow, radius: 10, x: 0, y: 5)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
}
