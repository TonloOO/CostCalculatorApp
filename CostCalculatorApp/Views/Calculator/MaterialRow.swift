//
//  MaterialCard.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-22.
//


import SwiftUI

struct MaterialRow: View {
    @Binding var material: Material
    @Binding var materialsBinding: [Material]
    var colorIndex: Int = 0
    var onDelete: (() -> Void)? = nil
    
    @State private var isExpanded: Bool = true

    @State private var showWarpPicker = false
    @State private var showWeftPicker = false
    @State private var warpExpanded = false
    @State private var weftExpanded = false
    @State private var showClearWarpConfirm = false
    @State private var showClearWeftConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 8) {
                // Color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(MaterialColors.color(for: colorIndex))
                    .frame(width: 4, height: 28)
                
                TextField("材料名称", text: $material.name)
                    .font(.system(size: 15, weight: .semibold))
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.error.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.Colors.tertiaryBackground)
                        .clipShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)

            if isExpanded {
                VStack(spacing: AppTheme.Spacing.small) {
                    // Warp section
                    Toggle(isOn: Binding(
                        get: { warpExpanded },
                        set: { newValue in
                            if !newValue && hasWarpData {
                                showClearWarpConfirm = true
                            } else {
                                warpExpanded = newValue
                            }
                        }
                    )) {
                        Text("经纱参数")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    if warpExpanded {
                        YarnInputField(
                            yarnValue: $material.warpYarnValue,
                            yarnTypeSelection: $material.warpYarnTypeSelection,
                            showPicker: $showWarpPicker,
                            label: "经纱"
                        )
                        SuffixTextField(label: "经纱纱价", text: $material.warpYarnPrice, suffix: "元", keyboardType: .decimalPad)
                        RatioSliderField(
                            label: "经纱占比",
                            ratio: Binding(
                                get: { material.warpRatio ?? "" },
                                set: { material.warpRatio = $0.isEmpty ? nil : $0 }
                            )
                        )
                    }

                    Divider()

                    // Weft section
                    Toggle(isOn: Binding(
                        get: { weftExpanded },
                        set: { newValue in
                            if !newValue && hasWeftData {
                                showClearWeftConfirm = true
                            } else {
                                weftExpanded = newValue
                            }
                        }
                    )) {
                        Text("纬纱参数")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    if weftExpanded {
                        YarnInputField(
                            yarnValue: $material.weftYarnValue,
                            yarnTypeSelection: $material.weftYarnTypeSelection,
                            showPicker: $showWeftPicker,
                            label: "纬纱"
                        )
                        SuffixTextField(label: "纬纱纱价", text: $material.weftYarnPrice, suffix: "元", keyboardType: .decimalPad)
                        RatioSliderField(
                            label: "纬纱占比",
                            ratio: Binding(
                                get: { material.weftRatio ?? "" },
                                set: { material.weftRatio = $0.isEmpty ? nil : $0 }
                            )
                        )
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            warpExpanded = !(material.warpYarnValue.isEmpty && material.warpYarnPrice.isEmpty && (material.warpRatio == nil || material.warpRatio?.isEmpty == true))
            weftExpanded = !(material.weftYarnValue.isEmpty && material.weftYarnPrice.isEmpty && (material.weftRatio == nil || material.weftRatio?.isEmpty == true))
        }
        .alert("确认清空经纱参数？", isPresented: $showClearWarpConfirm) {
            Button("清空", role: .destructive) {
                material.warpYarnValue = ""
                material.warpYarnTypeSelection = .dNumber
                material.warpYarnPrice = ""
                material.warpRatio = nil
                warpExpanded = false
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("已填写的经纱数据将被清空")
        }
        .alert("确认清空纬纱参数？", isPresented: $showClearWeftConfirm) {
            Button("清空", role: .destructive) {
                material.weftYarnValue = ""
                material.weftYarnTypeSelection = .dNumber
                material.weftYarnPrice = ""
                material.weftRatio = nil
                weftExpanded = false
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("已填写的纬纱数据将被清空")
        }
    }
    
    private var hasWarpData: Bool {
        !material.warpYarnValue.isEmpty || !material.warpYarnPrice.isEmpty || (material.warpRatio != nil && !material.warpRatio!.isEmpty)
    }
    
    private var hasWeftData: Bool {
        !material.weftYarnValue.isEmpty || !material.weftYarnPrice.isEmpty || (material.weftRatio != nil && !material.weftRatio!.isEmpty)
    }
}
