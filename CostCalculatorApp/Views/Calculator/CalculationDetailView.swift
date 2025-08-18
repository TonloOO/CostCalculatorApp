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
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // 客户信息卡片
                DetailCard(title: "客户信息") {
                    HStack {
                        Label(record.customerName ?? "未知", systemImage: "person.circle.fill")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        Spacer()
                    }
                }
                
                // 计算日期卡片
                DetailCard(title: "计算日期") {
                    HStack {
                        if let date = record.date {
                            Label("\(date, formatter: dateFormatter)", systemImage: "calendar")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.primaryText)
                        } else {
                            Label("未知时间", systemImage: "calendar")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        Spacer()
                    }
                }
                
                // 材料明细卡片
                DetailCard(title: isSingleMaterial ? "纱线信息" : "材料明细") {
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
                                        .padding(.top, AppTheme.Spacing.xSmall)
                                }
                                .tint(AppTheme.Colors.primary)
                            }
                        }
                    } else {
                        // Legacy single material record format
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                            if let warpYarnValue = record.warpYarnValue,
                               let warpYarnType = record.warpYarnTypeSelection {
                                InfoRow(label: "经纱规格", value: "\(warpYarnValue) \(warpYarnType)")
                            }
                            if let weftYarnValue = record.weftYarnValue,
                               let weftYarnType = record.weftYarnTypeSelection {
                                InfoRow(label: "纬纱规格", value: "\(weftYarnValue) \(weftYarnType)")
                            }
                            if let warpYarnPrice = record.warpYarnPrice {
                                InfoRow(label: "经纱纱价", value: "\(warpYarnPrice) 元")
                            }
                            if let weftYarnPrice = record.weftYarnPrice {
                                InfoRow(label: "纬纱纱价", value: "\(weftYarnPrice) 元")
                            }
                        }
                    }
                }

                // 计算结果卡片
                DetailCard(title: "计算结果", isHighlighted: true) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        ResultRow(label: "总经纱成本", value: String(format: "%.3f", record.warpCost), unit: "元/米")
                        ResultRow(label: "总经纱克重", value: String(format: "%.3f", record.warpWeight), unit: "克")
                        ResultRow(label: "总纬纱成本", value: String(format: "%.3f", record.weftCost), unit: "元/米")
                        ResultRow(label: "总纬纱克重", value: String(format: "%.3f", record.weftWeight), unit: "克")
                        ResultRow(label: "牵经费用", value: String(format: "%.3f", record.warpingCost), unit: "元/米")
                        ResultRow(label: "工费", value: String(format: "%.3f", record.laborCost), unit: "元/米")
                        ResultRow(label: "日产量", value: String(format: "%.3f", record.dailyProduct), unit: "米")
                        
                        Divider()
                            .padding(.vertical, AppTheme.Spacing.xSmall)
                        
                        HStack {
                            Text("总费用")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                            Spacer()
                            Text(String(format: "%.3f", record.totalCost))
                                .font(AppTheme.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.Colors.accent)
                            Text("元/米")
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                }
                
                // 输入参数卡片
                DetailCard(title: "输入参数") {
                    VStack(spacing: AppTheme.Spacing.small) {
                        if let boxNumber = record.boxNumber {
                            InfoRow(label: "筘号", value: boxNumber)
                        }
                        if let threading = record.threading {
                            InfoRow(label: "穿入", value: threading)
                        }
                        if let fabricWidth = record.fabricWidth {
                            InfoRow(label: "门幅", value: "\(fabricWidth) cm")
                        }
                        if let edgeFinishing = record.edgeFinishing {
                            InfoRow(label: "加边", value: "\(edgeFinishing) cm")
                        }
                        if let fabricShrinkage = record.fabricShrinkage {
                            InfoRow(label: "织缩", value: fabricShrinkage)
                        }
                        if let weftDensity = record.weftDensity {
                            InfoRow(label: "下机纬密", value: "\(weftDensity) 根/cm")
                        }
                        if let machineSpeed = record.machineSpeed {
                            InfoRow(label: "车速", value: "\(machineSpeed) RPM")
                        }
                        if let efficiency = record.efficiency {
                            InfoRow(label: "效率", value: "\(efficiency) %")
                        }
                        if let dailyLaborCost = record.dailyLaborCost {
                            InfoRow(label: "日工费", value: "\(dailyLaborCost) 元")
                        }
                        if let fixedCost = record.fixedCost {
                            InfoRow(label: "牵经费用", value: "\(fixedCost) 元/米")
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.Colors.groupedBackground)
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            // Only show material name if it's not "单材料"
            if material.material.name != "单材料" {
                InfoRow(label: "材料名称", value: material.material.name)
            }
            
            let warpEnabled = ((Double(material.material.warpRatio ?? "0") ?? 0) > 0) || material.warpWeight > 0 || material.warpCost > 0
            let weftEnabled = ((Double(material.material.weftRatio ?? "0") ?? 0) > 0) || material.weftWeight > 0 || material.weftCost > 0

            if warpEnabled {
                InfoRow(label: "经纱规格", value: "\(material.material.warpYarnValue) \(material.material.warpYarnTypeSelection.rawValue)")
                InfoRow(label: "经纱纱价", value: "\(material.material.warpYarnPrice) 元")
            }
            if weftEnabled {
                InfoRow(label: "纬纱规格", value: "\(material.material.weftYarnValue) \(material.material.weftYarnTypeSelection.rawValue)")
                InfoRow(label: "纬纱纱价", value: "\(material.material.weftYarnPrice) 元")
            }
            
            // Only show ratios if it's not a single material (ratio would be 1)
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

// MARK: - Supporting Views
struct DetailCard<Content: View>: View {
    let title: String
    var isHighlighted: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(isHighlighted ? AppTheme.Colors.primary : AppTheme.Colors.primaryText)
            
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
                .foregroundColor(AppTheme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
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
                .foregroundColor(AppTheme.Colors.secondaryText)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                Text(unit)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
        }
    }
}
