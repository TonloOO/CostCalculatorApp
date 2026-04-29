//
//  CloudKitThemedRow.swift
//  CostCalculatorApp
//
//  Extracted from ProfileView.swift
//

import SwiftUI

struct CloudKitThemedRow: View {
    @Bindable var cloudKitSettings: CloudKitSettingsManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "icloud")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.info)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("data_sync".localized())
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(cloudKitSettings.cloudKitStatusColor)
                            .frame(width: 7, height: 7)
                        Text(cloudKitSettings.cloudKitStatus)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
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
