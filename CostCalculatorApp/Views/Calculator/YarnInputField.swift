//
//  YarnInputField.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct YarnInputField: View {
    @Binding var yarnValue: String
    @Binding var yarnTypeSelection: YarnType
    @Binding var showPicker: Bool
    var label: String

	@FocusState private var isFocused: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
			Text("\(label)规格")
				.font(AppTheme.Typography.caption1)
				.foregroundColor(isFocused ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
			
			HStack(spacing: AppTheme.Spacing.xSmall) {
				TextField("", text: $yarnValue)
					.keyboardType(.decimalPad)
					.focused($isFocused)
					.font(AppTheme.Typography.body)
					.frame(maxWidth: .infinity, alignment: .leading)

				Menu {
					Button("D数") { yarnTypeSelection = .dNumber }
					Button("支数") { yarnTypeSelection = .yarnCount }
				} label: {
					HStack(spacing: 4) {
						Text(yarnTypeSelection.rawValue)
							.font(AppTheme.Typography.footnote)
							.foregroundColor(AppTheme.Colors.primaryText)
						Image(systemName: "chevron.down")
							.font(.system(size: 12))
							.foregroundColor(AppTheme.Colors.tertiaryText)
					}
				}
			}
			.padding(AppTheme.Spacing.small)
			.background(
				RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
					.fill(AppTheme.Colors.secondaryBackground)
			)
			.overlay(
				RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
					.stroke(isFocused ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
			)
		}
	}
}

