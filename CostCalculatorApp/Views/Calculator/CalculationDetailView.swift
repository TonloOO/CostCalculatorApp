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
    var dismissAction: (() -> Void)? = nil

    @Environment(\.displayScale) private var displayScale
    @State private var saveToastMessage: String?
    @State private var showSaveToast = false
    
    private var isSheetMode: Bool { dismissAction != nil }
    
    private var isSingleMaterial: Bool {
        if let data = record.materialsResult, let results = decodeMaterialsResult(from: data) {
            return results.count == 1 && results.first?.material.name == "单材料"
        }
        return record.warpYarnValue != nil && 
               record.weftYarnValue != nil && 
               record.warpYarnTypeSelection != nil && 
               record.weftYarnTypeSelection != nil
    }
    
    private var materialResults: [MaterialCalculationResult]? {
        guard let data = record.materialsResult else { return nil }
        return decodeMaterialsResult(from: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // 合并：客户信息 + 日期 + 总费用
                VStack(spacing: 0) {
                    // 客户 + 日期行
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(record.customerName ?? "未知", systemImage: "person.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            
                            if let date = record.date {
                                Label("\(date, formatter: dateFormatter)", systemImage: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, AppTheme.Spacing.small)
                    
                    Divider()
                        .padding(.bottom, AppTheme.Spacing.small)
                    
                    // 总费用醒目展示
                    HStack(alignment: .firstTextBaseline) {
                        Text("总费用")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                        Spacer()
                        Text(record.totalCost, format: .number.precision(.fractionLength(3)))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.accent)
                        Text("元/米")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                )
                
                // 材料明细卡片
                DetailCard(title: isSingleMaterial ? "纱线信息" : "材料明细") {
                    if let results = materialResults {
                        if isSingleMaterial {
                            MaterialDetailView(material: results.first!)
                        } else {
                            MaterialRatioBar(results: results, mode: .ratio)
                                .padding(.bottom, AppTheme.Spacing.small)
                            
                            ForEach(results, id: \.self) { result in
                                DisclosureGroup(result.material.name) {
                                    MaterialDetailView(material: result)
                                        .padding(.top, AppTheme.Spacing.xSmall)
                                }
                                .tint(AppTheme.Colors.primary)
                            }
                        }
                    } else {
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
                calculationResultsCard
                
                // 输入参数（默认折叠）
                DetailCard(title: "输入参数") {
                    DisclosureGroup("查看所有输入参数") {
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
                        .padding(.top, AppTheme.Spacing.xSmall)
                    }
                    .tint(AppTheme.Colors.primary)
                }
                
                // Sheet 模式下的操作按钮
                if isSheetMode {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button(action: saveScreenshotToAlbum) {
                            Label("保存截图", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                        }
                        .secondaryButton()
                        
                        Button(action: { dismissAction?() }) {
                            Text("完成")
                                .frame(maxWidth: .infinity)
                        }
                        .primaryButton()
                    }
                    .padding(.top, AppTheme.Spacing.small)
                }
            }
            .padding()
        }
        .background(AppTheme.Colors.groupedBackground)
        .navigationTitle(isSheetMode ? "计算结果" : "计算详情")
        .toolbar {
            if isSheetMode {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismissAction?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: EditCalculationView(record: record)) {
                        Text("编辑计算")
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showSaveToast, let message = saveToastMessage {
                Text(message)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(message.contains("成功") ? AppTheme.Colors.success : AppTheme.Colors.error)
                    )
                    .shadow(radius: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    // MARK: - 截图保存到相册
    @MainActor
    private func saveScreenshotToAlbum() {
        let renderer = ImageRenderer(content: screenshotContent)
        renderer.scale = displayScale

        guard let image = renderer.uiImage else {
            showToast("截图生成失败")
            return
        }

        let saver = ImageSaver { success in
            if success {
                HapticFeedbackManager.shared.notification(type: .success)
                showToast("已保存到相册")
            } else {
                HapticFeedbackManager.shared.notification(type: .error)
                showToast("保存失败，请检查相册权限")
            }
        }
        saver.saveToAlbum(image: image)
    }

    private func showToast(_ message: String) {
        saveToastMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showSaveToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.3)) {
                showSaveToast = false
            }
        }
    }
    
    /// 用于截图渲染的纯视图内容（不含按钮和导航栏）
    private var screenshotContent: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // 标题
            HStack {
                Text("纺织成本计算结果")
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                Spacer()
            }
            .padding(.bottom, AppTheme.Spacing.xSmall)
            
            // 客户信息
            if let name = record.customerName, !name.isEmpty {
                DetailCard(title: "客户信息") {
                    HStack {
                        Label(name, systemImage: "person.circle.fill")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                        Spacer()
                    }
                }
            }
            
            // 计算结果
            screenshotResultCards
            
            // 日期水印
            HStack {
                Spacer()
                if let date = record.date {
                    Text("计算于 \(date, formatter: dateFormatter)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.groupedBackground)
        .containerRelativeFrame(.horizontal)
    }
    
    @ViewBuilder
    private var screenshotResultCards: some View {
        if !isSingleMaterial, let results = materialResults, results.count > 1 {
            ForEach(results, id: \.self) { result in
                let warpEnabled = ((Double(result.material.warpRatio ?? "0") ?? 0) > 0) || result.warpWeight > 0
                let weftEnabled = ((Double(result.material.weftRatio ?? "0") ?? 0) > 0) || result.weftWeight > 0
                
                DetailCard(title: result.material.name) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        if warpEnabled {
                            ResultRow(label: "经纱成本", value: String(format: "%.3f", result.warpCost), unit: "元/米")
                            ResultRow(label: "经纱克重", value: String(format: "%.3f", result.warpWeight), unit: "克")
                        }
                        if weftEnabled {
                            ResultRow(label: "纬纱成本", value: String(format: "%.3f", result.weftCost), unit: "元/米")
                            ResultRow(label: "纬纱克重", value: String(format: "%.3f", result.weftWeight), unit: "克")
                        }
                    }
                }
            }
            
            DetailCard(title: "汇总", isHighlighted: true) {
                VStack(spacing: AppTheme.Spacing.small) {
                    ResultRow(label: "总经纱成本", value: String(format: "%.3f", record.warpCost), unit: "元/米")
                    ResultRow(label: "总纬纱成本", value: String(format: "%.3f", record.weftCost), unit: "元/米")
                    ResultRow(label: "牵经费用", value: String(format: "%.3f", record.warpingCost), unit: "元/米")
                    ResultRow(label: "工费", value: String(format: "%.3f", record.laborCost), unit: "元/米")
                    ResultRow(label: "日产量", value: String(format: "%.3f", record.dailyProduct), unit: "米")
                    Divider()
                    totalCostRow
                }
            }
        } else {
            DetailCard(title: "计算结果", isHighlighted: true) {
                VStack(spacing: AppTheme.Spacing.small) {
                    ResultRow(label: "经纱成本", value: String(format: "%.3f", record.warpCost), unit: "元/米")
                    ResultRow(label: "经纱克重", value: String(format: "%.3f", record.warpWeight), unit: "克")
                    ResultRow(label: "纬纱成本", value: String(format: "%.3f", record.weftCost), unit: "元/米")
                    ResultRow(label: "纬纱克重", value: String(format: "%.3f", record.weftWeight), unit: "克")
                    ResultRow(label: "牵经费用", value: String(format: "%.3f", record.warpingCost), unit: "元/米")
                    ResultRow(label: "工费", value: String(format: "%.3f", record.laborCost), unit: "元/米")
                    ResultRow(label: "日产量", value: String(format: "%.3f", record.dailyProduct), unit: "米")
                    Divider()
                    totalCostRow
                }
            }
        }
    }
    
    // MARK: - 计算结果卡片
    @ViewBuilder
    private var calculationResultsCard: some View {
        if !isSingleMaterial, let results = materialResults, results.count > 1 {
            // 多材料：按材料分组展示
            ForEach(results, id: \.self) { result in
                let warpEnabled = ((Double(result.material.warpRatio ?? "0") ?? 0) > 0) || result.warpWeight > 0
                let weftEnabled = ((Double(result.material.weftRatio ?? "0") ?? 0) > 0) || result.weftWeight > 0
                
                DetailCard(title: result.material.name) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        if warpEnabled {
                            ResultRow(label: "经纱成本", value: String(format: "%.3f", result.warpCost), unit: "元/米")
                            ResultRow(label: "经纱克重", value: String(format: "%.3f", result.warpWeight), unit: "克")
                        }
                        if weftEnabled {
                            ResultRow(label: "纬纱成本", value: String(format: "%.3f", result.weftCost), unit: "元/米")
                            ResultRow(label: "纬纱克重", value: String(format: "%.3f", result.weftWeight), unit: "克")
                        }
                    }
                }
            }
            
            // 汇总卡片
            DetailCard(title: "汇总", isHighlighted: true) {
                VStack(spacing: AppTheme.Spacing.small) {
                    // 成本占比条形图
                    MaterialRatioBar(results: results, mode: .cost)
                        .padding(.bottom, AppTheme.Spacing.xSmall)
                    
                    ResultRow(label: "总经纱成本", value: String(format: "%.3f", record.warpCost), unit: "元/米")
                    ResultRow(label: "总经纱克重", value: String(format: "%.3f", record.warpWeight), unit: "克")
                    ResultRow(label: "总纬纱成本", value: String(format: "%.3f", record.weftCost), unit: "元/米")
                    ResultRow(label: "总纬纱克重", value: String(format: "%.3f", record.weftWeight), unit: "克")
                    ResultRow(label: "牵经费用", value: String(format: "%.3f", record.warpingCost), unit: "元/米")
                    ResultRow(label: "工费", value: String(format: "%.3f", record.laborCost), unit: "元/米")
                    ResultRow(label: "日产量", value: String(format: "%.3f", record.dailyProduct), unit: "米")
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xSmall)
                    
                    totalCostRow
                }
            }
        } else {
            // 单材料
            DetailCard(title: "计算结果", isHighlighted: true) {
                VStack(spacing: AppTheme.Spacing.small) {
                    ResultRow(label: "经纱成本", value: String(format: "%.3f", record.warpCost), unit: "元/米")
                    ResultRow(label: "经纱克重", value: String(format: "%.3f", record.warpWeight), unit: "克")
                    ResultRow(label: "纬纱成本", value: String(format: "%.3f", record.weftCost), unit: "元/米")
                    ResultRow(label: "纬纱克重", value: String(format: "%.3f", record.weftWeight), unit: "克")
                    ResultRow(label: "牵经费用", value: String(format: "%.3f", record.warpingCost), unit: "元/米")
                    ResultRow(label: "工费", value: String(format: "%.3f", record.laborCost), unit: "元/米")
                    ResultRow(label: "日产量", value: String(format: "%.3f", record.dailyProduct), unit: "米")
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xSmall)
                    
                    totalCostRow
                }
            }
        }
    }
    
    private var totalCostRow: some View {
        HStack {
            Text("总费用")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)
            Spacer()
            Text(record.totalCost, format: .number.precision(.fractionLength(3)))
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.accent)
            Text("元/米")
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private func decodeMaterialsResult(from data: Data) -> [MaterialCalculationResult]? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([MaterialCalculationResult].self, from: data)
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

