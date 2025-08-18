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
    @State private var isExpanded: Bool = false

    // Separate picker and section expansion states for warp and weft yarn fields
    @State private var showWarpPicker = false
    @State private var showWeftPicker = false
    @State private var warpExpanded = false
    @State private var weftExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Left editable name, Right expand/collapse button
            HStack(spacing: 8) {
                TextField("材料名称", text: $material.name)
                    .font(.headline)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    withAnimation { isExpanded.toggle() }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(.systemGray))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 2)

            if isExpanded {
                Group {
                    // Warp Switch
                    Toggle(isOn: $warpExpanded) {
                        Text("经纱参数")
                            .font(.headline)
                            .foregroundColor(Color(.systemGray))
                    }
                    .onChange(of: warpExpanded) {
                        if !warpExpanded {
                            material.warpYarnValue = ""
                            material.warpYarnTypeSelection = .dNumber
                            material.warpYarnPrice = ""
                            material.warpRatio = nil
                        }
                    }

                    if warpExpanded {
                        YarnInputField(
                            yarnValue: $material.warpYarnValue,
                            yarnTypeSelection: $material.warpYarnTypeSelection,
                            showPicker: $showWarpPicker,
                            label: "经纱"
                        )
                        SuffixTextField(label: "经纱纱价", text: $material.warpYarnPrice, suffix: "元", keyboardType: .decimalPad)
                        SuffixTextField(
                            label: "经纱占比",
                            text: Binding(
                                get: { material.warpRatio ?? "" },
                                set: { material.warpRatio = $0.isEmpty ? nil : $0 }
                            ),
                            suffix: "",
                            keyboardType: .decimalPad
                        )
                    }

                    // Weft Switch
                    Toggle(isOn: $weftExpanded) {
                        Text("纬纱参数")
                            .font(.headline)
                            .foregroundColor(Color(.systemGray))
                    }
                    .onChange(of: weftExpanded) {
                        if !weftExpanded {
                            material.weftYarnValue = ""
                            material.weftYarnTypeSelection = .dNumber
                            material.weftYarnPrice = ""
                            material.weftRatio = nil
                        }
                    }

                    if weftExpanded {
                        YarnInputField(
                            yarnValue: $material.weftYarnValue,
                            yarnTypeSelection: $material.weftYarnTypeSelection,
                            showPicker: $showWeftPicker,
                            label: "纬纱"
                        )
                        SuffixTextField(label: "纬纱纱价", text: $material.weftYarnPrice, suffix: "元", keyboardType: .decimalPad)
                        SuffixTextField(
                            label: "纬纱占比",
                            text: Binding(
                                get: { material.weftRatio ?? "" },
                                set: { material.weftRatio = $0.isEmpty ? nil : $0 }
                            ),
                            suffix: "",
                            keyboardType: .decimalPad
                        )
                    }
                }
                .padding(.leading, 10)
                .padding(.top, 2)
            }
        }
        .onAppear {
            warpExpanded = !(material.warpYarnValue.isEmpty && material.warpYarnPrice.isEmpty && (material.warpRatio == nil || material.warpRatio?.isEmpty == true))
            weftExpanded = !(material.weftYarnValue.isEmpty && material.weftYarnPrice.isEmpty && (material.weftRatio == nil || material.weftRatio?.isEmpty == true))
        }
    }
}
