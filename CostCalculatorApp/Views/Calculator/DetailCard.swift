//
//  DetailCard.swift
//  CostCalculatorApp
//
//  Extracted from CalculationDetailView.swift
//

import SwiftUI

struct DetailCard<Content: View>: View {
    let title: String
    var isHighlighted: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(isHighlighted ? AppTheme.Colors.primary : AppTheme.Colors.primaryText)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(isHighlighted ? AppTheme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                Text(unit)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
        }
    }
}
