//
//  CalculationDetailView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct CalculationDetailView: View {
    let record: CalculationRecord

    var body: some View {
        Form {
            Section(header: Text("客户信息")) {
                Text("客户名称/单号: \(record.customerName)")
            }
            
            Section(header: Text("计算日期")) {
                Text("\(record.date, formatter: dateFormatter)")
            }
            
            Section(header: Text("计算结果")) {
                Text("经纱成本：\(record.warpCost, specifier: "%.3f") 元/米")
                Text("纬纱成本：\(record.weftCost, specifier: "%.3f") 元/米")
                Text("牵经费用：\(record.warpingCost, specifier: "%.3f") 元/米")
                Text("工费：\(record.laborCost, specifier: "%.3f") 元/米")
                Text("日产量：\(record.dailyProduct, specifier: "%.3f") 米")
                Text("总费用：\(record.totalCost, specifier: "%.3f") 元/米")
                    .font(.title) // Larger font
                    .fontWeight(.bold) // Bold text
                    .foregroundColor(.red) // Highlight in red
            }
            
            Section(header: Text("输入参数")) {
                Text("筘号: \(record.boxNumber)")
                Text("穿入: \(record.threading)")
                Text("门幅: \(record.fabricWidth) cm")
                Text("加边: \(record.edgeFinishing) cm")
                Text("经纱规格 (\(record.warpYarnTypeSelection.rawValue)): \(record.warpYarnValue)")
                Text("纬纱规格 (\(record.weftYarnTypeSelection.rawValue)): \(record.weftYarnValue)")
                Text("织缩: \(record.fabricShrinkage)")
                Text("经纱纱价: \(record.warpYarnPrice) 元/kg")
                Text("纬纱纱价: \(record.weftYarnPrice) 元/kg")
                Text("下机纬密: \(record.weftDensity) 根/cm")
                Text("车速: \(record.machineSpeed)")
                Text("效率: \(record.efficiency) %")
                Text("日工费: \(record.dailyLaborCost) 元")
                Text("牵经费用: \(record.fixedCost) 元/米")
            }

        }
        .navigationTitle("计算详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditCalculationView(record: record)) {
                    Text("编辑计算")
                }
            }
        }
    }

    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")  // Set locale to Chinese
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"    // Custom date format in Chinese
        return formatter
    }
}
