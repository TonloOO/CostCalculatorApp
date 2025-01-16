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
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Group {
                    // Material Name
                    SuffixTextField(label: "材料名称", text: $material.name, suffix: "")
                    
                    // Warp Switch
                    Toggle(isOn: $warpExpanded) {
                        Text("经纱参数")
                            .font(.headline)
                            .foregroundColor(Color(.systemGray))
                    }
                    .onChange(of: warpExpanded) {
                        if !warpExpanded {
                            // Warp toggle is switched off, clear the warp data
                            material.warpYarnValue = ""
                            material.warpYarnTypeSelection = .dNumber // Set to default if needed
                            material.warpYarnPrice = ""  
                            material.warpRatio = nil
                        }
                    }
                    
                    if warpExpanded {
                        // Warp Parameters
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
                                get: { material.warpRatio ?? material.ratio },
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
                            // Weft toggle is switched off, clear the weft data
                            material.weftYarnValue = ""
                            material.weftYarnTypeSelection = .dNumber // Set to default if needed
                            material.weftYarnPrice = ""
                            material.weftRatio = nil
                        }
                    }
                    
                    if weftExpanded {
                        // Weft Parameters
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
                                get: { material.weftRatio ?? material.ratio },
                                set: { material.weftRatio = $0.isEmpty ? nil : $0 }
                            ),
                            suffix: "",
                            keyboardType: .decimalPad
                        )
                    }
                }
                .padding(.leading, 10)
            },
            label: {
                Text(material.name)
                    .font(.headline)
            }
        )
        .onAppear {
            // Initialize the toggles based on existing data
            warpExpanded = !material.warpYarnValue.isEmpty || !material.warpYarnPrice.isEmpty
            weftExpanded = !material.weftYarnValue.isEmpty || !material.weftYarnPrice.isEmpty
        }
    }
}
