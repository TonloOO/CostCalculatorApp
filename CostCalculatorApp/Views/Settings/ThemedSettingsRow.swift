//
//  ThemedSettingsRow.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

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
