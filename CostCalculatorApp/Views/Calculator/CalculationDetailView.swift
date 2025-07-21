//
//  CalculationDetailView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI
import CoreData

struct CalculationDetailView: View {
    @ObservedObject var record: CalculationRecord
    
    private var isSingleMaterial: Bool {
        if let data = record.materialsResult, let results = decodeMaterialsResult(from: data) {
            return results.count == 1 && results.first?.material.name == "单材料"
        }
        // For legacy records, check if we have yarn data
        return record.warpYarnValue != nil && 
               record.weftYarnValue != nil && 
               record.warpYarnTypeSelection != nil && 
               record.weftYarnTypeSelection != nil
    }

    var body: some View {
        Form {
            Section(header: Text("客户信息")) {
                Text("客户名称/单号: \(record.customerName ?? "未知")")
            }
            
            Section(header: Text("计算日期")) {
                if let date = record.date {
                    Text("\(date, formatter: dateFormatter)")
                } else {
                    Text("未知时间")
                }
            }
            
            Section(header: Text(isSingleMaterial ? "纱线信息" : "材料明细")) {
                if let data = record.materialsResult, let results: [MaterialCalculationResult] = decodeMaterialsResult(from: data) {
                    // Check if this is a single material calculation
                    if isSingleMaterial {
                        // For single material, show details directly without DisclosureGroup
                        MaterialDetailView(material: results.first!)
                    } else {
                        // For multiple materials, use DisclosureGroup
                        ForEach(results, id: \.self) { result in
                            DisclosureGroup(result.material.name) {
                                MaterialDetailView(material: result)
                            }
                        }
                    }
                } else {
                    // Legacy single material record format
                    VStack(alignment: .leading, spacing: 8) {
                        if let warpYarnValue = record.warpYarnValue,
                           let warpYarnType = record.warpYarnTypeSelection {
                            Text("经纱规格: \(warpYarnValue) \(warpYarnType)")
                        }
                        if let weftYarnValue = record.weftYarnValue,
                           let weftYarnType = record.weftYarnTypeSelection {
                            Text("纬纱规格: \(weftYarnValue) \(weftYarnType)")
                        }
                        if let warpYarnPrice = record.warpYarnPrice {
                            Text("经纱纱价: \(warpYarnPrice) 元")
                        }
                        if let weftYarnPrice = record.weftYarnPrice {
                            Text("纬纱纱价: \(weftYarnPrice) 元")
                        }
                    }
                    .padding(8)
                }
            }

            Section(header: Text("计算结果")) {
                Text("总经纱成本：\(record.warpCost, specifier: "%.3f") 元/米")
                Text("总经纱克重：\(record.warpWeight, specifier: "%.3f") 克")
                Text("总纬纱成本：\(record.weftCost, specifier: "%.3f") 元/米")
                Text("总纬纱克重：\(record.weftWeight, specifier: "%.3f") 克")
                Text("牵经费用：\(record.warpingCost, specifier: "%.3f") 元/米")
                Text("工费：\(record.laborCost, specifier: "%.3f") 元/米")
                Text("日产量：\(record.dailyProduct, specifier: "%.3f") 米")
                Text("总费用：\(record.totalCost, specifier: "%.3f") 元/米")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            Section(header: Text("输入参数")) {
                if let boxNumber = record.boxNumber {
                    Text("筘号: \(boxNumber)")
                }
                if let threading = record.threading {
                    Text("穿入: \(threading)")
                }
                if let fabricWidth = record.fabricWidth {
                    Text("门幅: \(fabricWidth) cm")
                }
                if let edgeFinishing = record.edgeFinishing {
                    Text("加边: \(edgeFinishing) cm")
                }
                if let fabricShrinkage = record.fabricShrinkage {
                    Text("织缩: \(fabricShrinkage)")
                }
                if let weftDensity = record.weftDensity {
                    Text("下机纬密: \(weftDensity) 根/cm")
                }
                if let machineSpeed = record.machineSpeed {
                    Text("车速: \(machineSpeed)")
                }
                if let efficiency = record.efficiency {
                    Text("效率: \(efficiency) %")
                }
                if let dailyLaborCost = record.dailyLaborCost {
                    Text("日工费: \(dailyLaborCost) 元")
                }
                if let fixedCost = record.fixedCost {
                    Text("牵经费用: \(fixedCost) 元/米")
                }
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

    private func decodeMaterialsResult(from data: Data) -> [MaterialCalculationResult]? {
        let decoder = JSONDecoder()
        do {
            let decodedResults = try decoder.decode([MaterialCalculationResult].self, from: data)
            return decodedResults
        } catch {
            print("Error decoding materials result: \(error)")
            return nil
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter
    }
}


struct MaterialDetailView: View {
    var material: MaterialCalculationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Only show material name if it's not "单材料"
            if material.material.name != "单材料" {
                Text("材料名称: \(material.material.name)")
            }
            
            Text("经纱规格: \(material.material.warpYarnValue) \(material.material.warpYarnTypeSelection.rawValue)")
            Text("纬纱规格: \(material.material.weftYarnValue) \(material.material.weftYarnTypeSelection.rawValue)")
            Text("经纱纱价: \(material.material.warpYarnPrice) 元")
            Text("纬纱纱价: \(material.material.weftYarnPrice) 元")
            
            // Only show ratios if it's not a single material (ratio would be 1)
            if material.material.name != "单材料" {
                Text("经纱占比: \(material.material.warpRatio ?? material.material.ratio)")
                Text("纬纱占比: \(material.material.weftRatio ?? material.material.ratio)")
            }
        }
        .padding(8)
    }
}
