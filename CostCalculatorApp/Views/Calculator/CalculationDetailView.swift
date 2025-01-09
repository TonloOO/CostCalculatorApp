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

    var body: some View {
        Form {
            Section(header: Text("客户信息")) {
                Text("客户名称/单号: \(record.customerName!)")
            }
            
            Section(header: Text("计算日期")) {
                Text("\(record.date!, formatter: dateFormatter)")
            }
            
            Section(header: Text("材料明细")) {
                if let data = record.materialsResult, let results: [MaterialCalculationResult] = decodeMaterialsResult(from: data) {
                    ForEach(results, id: \.self) { result in
                        DisclosureGroup(result.material.name) {
                            MaterialDetailView(material: result)
                        }
                    }
                } else {
                    DisclosureGroup("材料明细") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("材料名称: 未知")
                            Text("经纱规格: \(record.warpYarnValue!) \(record.warpYarnTypeSelection!)")
                            Text("纬纱规格: \(record.weftYarnValue!) \(record.weftYarnTypeSelection!)")
                            Text("经纱纱价: \(record.warpYarnPrice!) 元")
                            Text("纬纱纱价: \(record.weftYarnPrice!) 元")
                            Text("比例: 1")
                            Divider()
                            Text("经纱克重: \(record.warpWeight, specifier: "%.3f") g")
                            Text("经纱成本: \(record.warpCost, specifier: "%.3f") 元")
                            Text("纬纱克重: \(record.weftWeight, specifier: "%.3f") g")
                            Text("纬纱成本: \(record.weftCost, specifier: "%.3f") 元")
                        }
                    }
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
                Text("筘号: \(record.boxNumber!)")
                Text("穿入: \(record.threading!)")
                Text("门幅: \(record.fabricWidth!) cm")
                Text("加边: \(record.edgeFinishing!) cm")
                Text("织缩: \(record.fabricShrinkage!)")
                Text("下机纬密: \(record.weftDensity!) 根/cm")
                Text("车速: \(record.machineSpeed!)")
                Text("效率: \(record.efficiency!) %")
                Text("日工费: \(record.dailyLaborCost!) 元")
                Text("牵经费用: \(record.fixedCost!) 元/米")
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
    var material: MaterialCalculationResult  // Just passing the value
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("材料名称: \(material.material.name)")
            Text("经纱规格: \(material.material.warpYarnValue) \(material.material.warpYarnTypeSelection.rawValue)")
            Text("纬纱规格: \(material.material.weftYarnValue) \(material.material.weftYarnTypeSelection.rawValue)")
            Text("经纱纱价: \(material.material.warpYarnPrice) 元")
            Text("纬纱纱价: \(material.material.weftYarnPrice) 元")
            Text("经纱占比: \(material.material.warpRatio ?? material.material.ratio)")
            Text("纬纱占比: \(material.material.weftRatio ?? material.material.ratio)")
            Divider()
            Text("经纱克重: \(material.warpWeight, specifier: "%.3f") g")
            Text("经纱成本: \(material.warpCost, specifier: "%.3f") 元")
            Text("纬纱克重: \(material.weftWeight, specifier: "%.3f") g")
            Text("纬纱成本: \(material.weftCost, specifier: "%.3f") 元")
        }
        .padding(8)
    }
}
