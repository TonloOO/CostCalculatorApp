//
//  MaterialDetailView.swift
//  CostCalculatorApp
//
//  Extracted from CalculationDetailView.swift
//

import SwiftUI

struct MaterialDetailView: View {
    var material: MaterialCalculationResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            if material.material.name != "单材料" {
                InfoRow(label: "材料名称", value: material.material.name)
            }

            let warpEnabled = ((Double(material.material.warpRatio ?? "0") ?? 0) > 0) || material.warpWeight > 0 || material.warpCost > 0
            let weftEnabled = ((Double(material.material.weftRatio ?? "0") ?? 0) > 0) || material.weftWeight > 0 || material.weftCost > 0

            if warpEnabled {
                InfoRow(label: "经纱规格", value: "\(material.material.warpYarnValue) \(material.material.warpYarnTypeSelection.rawValue)")
                InfoRow(label: "经纱纱价", value: "\(material.material.warpYarnPrice) 元")
                InfoRow(label: "经纱克重", value: String(format: "%.3f 克", material.warpWeight))
                InfoRow(label: "经纱成本", value: String(format: "%.3f 元/米", material.warpCost))
            }
            if weftEnabled {
                InfoRow(label: "纬纱规格", value: "\(material.material.weftYarnValue) \(material.material.weftYarnTypeSelection.rawValue)")
                InfoRow(label: "纬纱纱价", value: "\(material.material.weftYarnPrice) 元")
                InfoRow(label: "纬纱克重", value: String(format: "%.3f 克", material.weftWeight))
                InfoRow(label: "纬纱成本", value: String(format: "%.3f 元/米", material.weftCost))
            }

            if material.material.name != "单材料" {
                if warpEnabled {
                    InfoRow(label: "经纱占比", value: material.material.warpRatio ?? "0")
                }
                if weftEnabled {
                    InfoRow(label: "纬纱占比", value: material.material.weftRatio ?? "0")
                }
            }
        }
    }
}
