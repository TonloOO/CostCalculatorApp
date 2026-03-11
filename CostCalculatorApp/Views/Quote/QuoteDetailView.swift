//
//  QuoteDetailView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-10.
//

import SwiftUI

struct QuoteDetailView: View {
    let quoteNo: String
    @StateObject private var viewModel = QuoteDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "加载报价详情...")
                } else if let error = viewModel.errorMessage {
                    errorContent(error)
                } else if let detail = viewModel.detail {
                    detailContent(detail)
                }
            }
            .navigationTitle(quoteNo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.load(quoteNo: quoteNo)
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ detail: QuoteDetail) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                headerSection(detail)
                basicInfoSection(detail)
                specsSection(detail)
                productionSection(detail)
                pricingSection(detail)
                costBreakdownSection(detail)
                materialsSection(detail)
                finishSection(detail)
                calculationSection()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.groupedBackground)
    }

    // MARK: - Header

    private func headerSection(_ d: QuoteDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(d.quoteNo)
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.primaryText)

                    if let name = d.materialName, !name.isEmpty {
                        Text(name)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }

                Spacer()

                if let statusText = d.normalizedStatus?.label ?? d.status {
                    Text(statusText)
                        .font(AppTheme.Typography.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor(d.normalizedStatus))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor(d.normalizedStatus).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if let price = d.price {
                HStack {
                    Text("报价单价")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    Spacer()
                    Text(String(format: "¥%.2f", price))
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }

    // MARK: - Basic Info

    private func basicInfoSection(_ d: QuoteDetail) -> some View {
        DetailSection(title: "基础信息", icon: "info.circle") {
            DetailGrid {
                DetailCell(label: "客户", value: d.customerName)
                DetailCell(label: "产品编号", value: d.materialNo)
                DetailCell(label: "业务员", value: d.salesName)
                DetailCell(label: "订单类型", value: d.orderType)
                DetailCell(label: "结算方式", value: d.balanceType)
                DetailCell(label: "联系人", value: d.linkMan)
                DetailCell(label: "报价日期", value: d.quoteTime)
                DetailCell(label: "交期", value: d.deliveryDate)
                DetailCell(label: "订单数量", value: fmtNum(d.orderQty))
                DetailCell(label: "币种", value: d.currency)
            }
            if let remark = d.remark, !remark.isEmpty {
                HStack(alignment: .top) {
                    Text("备注")
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        .frame(width: 60, alignment: .leading)
                    Text(remark)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Specs

    private func specsSection(_ d: QuoteDetail) -> some View {
        DetailSection(title: "规格参数", icon: "ruler") {
            DetailGrid {
                DetailCell(label: "门幅", value: fmtDec(d.width))
                DetailCell(label: "筘号", value: fmtDec(d.reedId))
                DetailCell(label: "筘入", value: fmtDec(d.fastenerRange))
                DetailCell(label: "废边长度cm", value: fmtDec(d.sideLength))
                DetailCell(label: "经缩%", value: fmtDec(d.warpWastagePercent))
                DetailCell(label: "总经根数", value: d.beamTotalEnd.map { "\($0)" })
                DetailCell(label: "经密", value: fmtDec(d.warpDensity))
                DetailCell(label: "纬密", value: fmtDec(d.weftDensity))
            }
        }
    }

    // MARK: - Production

    private func productionSection(_ d: QuoteDetail) -> some View {
        DetailSection(title: "生产参数", icon: "gearshape.2") {
            DetailGrid {
                DetailCell(label: "车速", value: fmtDec(d.weaveSpeed))
                DetailCell(label: "综合效率%", value: fmtDec(d.weaveEff))
                DetailCell(label: "织造日产量", value: fmtDec(d.weaveDayOutput))
                DetailCell(label: "织造日工资", value: fmtPrice(d.weaveDaySaleCost))
                DetailCell(label: "浆纱供应商", value: d.sizingProviderName)
            }
        }
    }

    // MARK: - Pricing

    private func pricingSection(_ d: QuoteDetail) -> some View {
        DetailSection(title: "价格信息", icon: "yensign.circle") {
            DetailGrid {
                DetailCell(label: "报价单价", value: fmtPrice(d.price))
                DetailCell(label: "成本单价", value: fmtPrice(d.costPrice))
                DetailCell(label: "原料单价", value: fmtPrice(d.yarnPrice))
                DetailCell(label: "织价", value: fmtPrice(d.weavePrice))
                DetailCell(label: "浆纱单价", value: fmtPrice(d.sizingPrice))
                DetailCell(label: "磨毛单价", value: fmtPrice(d.sandingPrice))
                DetailCell(label: "标准工费", value: fmtPrice(d.stdWeavePrice))
                DetailCell(label: "小样费用", value: fmtPrice(d.sampleCost))
                DetailCell(label: "利润率%", value: fmtDec(d.profitRate))
                DetailCell(label: "总金额", value: fmtPrice(d.amount))
            }
        }
    }

    // MARK: - Cost Breakdown

    private func costBreakdownSection(_ d: QuoteDetail) -> some View {
        let items: [(String, Double?)] = [
            ("纱线成本", d.yarnCost), ("染色成本", d.dyeCost),
            ("浆纱成本", d.sizingCost), ("织造成本", d.weaveCost),
            ("后整理", d.finishCost), ("检测费", d.testCost),
            ("修补费", d.repairCost), ("管理费", d.managerCost),
            ("运输费", d.traficCost), ("包装费", d.packageCost),
            ("其他费用", d.otherCost),
        ]
        let hasAny = items.contains { $0.1 != nil && $0.1 != 0 }
        if !hasAny { return AnyView(EmptyView()) }

        return AnyView(
            DetailSection(title: "成本明细", icon: "list.bullet.rectangle") {
                DetailGrid {
                    ForEach(items.filter { $0.1 != nil && $0.1 != 0 }, id: \.0) { item in
                        DetailCell(label: item.0, value: fmtPrice(item.1))
                    }
                }
            }
        )
    }

    // MARK: - Materials Table

    private func materialsSection(_ d: QuoteDetail) -> some View {
        guard let materials = d.materials, !materials.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            DetailSection(title: "原料成本", icon: "tablecells") {
                ForEach(materials) { m in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("#\(m.rowNo ?? 0)")
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                                .frame(width: 24)

                            if let usage = m.usage {
                                Text(usage)
                                    .font(AppTheme.Typography.caption1)
                                    .fontWeight(.medium)
                                    .foregroundColor(usage == "经纱" ? AppTheme.Colors.primary : AppTheme.Colors.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        (usage == "经纱" ? AppTheme.Colors.primary : AppTheme.Colors.accent).opacity(0.1)
                                    )
                                    .cornerRadius(4)
                            }

                            Text(m.materialName ?? "-")
                                .font(AppTheme.Typography.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .lineLimit(1)

                            Spacer()

                            if let no = m.materialNo, !no.isEmpty {
                                Text(no)
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                            }
                        }

                        HStack(spacing: AppTheme.Spacing.medium) {
                            materialMetric(materialSpecLabel(for: m), materialSpecValue(for: m))
                            materialMetric("用纱量", fmtDec(m.yarnUseQty))
                            materialMetric("根数", fmtDec(m.yarnQty))
                            materialMetric("用量kg", fmtDec(m.orderYarnQty))
                        }

                        HStack(spacing: AppTheme.Spacing.medium) {
                            materialMetric("单价", fmtPrice(m.unitPrice))
                            materialMetric("加工价", fmtPrice(m.yarnPrice))
                            if let provider = m.providerName, !provider.isEmpty {
                                materialMetric("供应商", provider)
                            }
                        }

                        if let remark = m.remark, !remark.isEmpty {
                            Text(remark)
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                        }
                    }
                    .padding(AppTheme.Spacing.small)
                    .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        )
    }

    // MARK: - Finish Details

    private func finishSection(_ d: QuoteDetail) -> some View {
        guard let finishes = d.finishDetails, !finishes.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            DetailSection(title: "后整理明细", icon: "paintbrush") {
                ForEach(finishes) { f in
                    HStack {
                        Text(f.finishMode ?? "-")
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        Spacer()
                        if let count = f.count {
                            Text("\(count)次")
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        if let price = f.price {
                            Text(String(format: "¥%.2f", price))
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        )
    }

    // MARK: - Calculation

    private func calculationSection() -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Button(action: {
                viewModel.runCalculation()
            }) {
                HStack {
                    Image(systemName: "function")
                    Text("重新计算")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.medium)
                .background(AppTheme.Colors.primaryGradient)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }

            if let result = viewModel.calcResult {
                DetailSection(title: "计算结果", icon: "checkmark.circle") {
                    DetailGrid {
                        DetailCell(label: "日产量", value: String(format: "%.2f 米", result.dailyProduct))
                        DetailCell(label: "织造工费", value: String(format: "¥%.4f", result.laborCost))
                        DetailCell(label: "经纱成本", value: String(format: "¥%.4f", result.warpCost))
                        DetailCell(label: "纬纱成本", value: String(format: "¥%.4f", result.weftCost))
                        DetailCell(label: "浆纱费", value: String(format: "¥%.4f", result.warpingCost))
                        DetailCell(label: "总成本", value: String(format: "¥%.4f", result.totalCost))
                    }
                }
            }
        }
    }

    // MARK: - Error

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.warning)
            Text(message)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxLarge)
            Button("重试") {
                Task { await viewModel.load(quoteNo: quoteNo) }
            }
        }
    }

    // MARK: - Helpers

    private func materialMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.tertiaryText)
            Text(value)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.primaryText)
        }
    }

    private func statusColor(_ status: QuoteStatus?) -> Color {
        switch status {
        case .editing:  return AppTheme.Colors.warning
        case .submitted: return AppTheme.Colors.primary
        case .approved: return AppTheme.Colors.success
        default: return AppTheme.Colors.tertiaryText
        }
    }

    private func fmtPrice(_ v: Double?) -> String {
        guard let v else { return "-" }
        return String(format: "¥%.2f", v)
    }
    private func fmtDec(_ v: Double?) -> String {
        guard let v else { return "-" }
        return String(format: "%.2f", v)
    }
    private func fmtNum(_ v: Double?) -> String {
        guard let v else { return "-" }
        return String(format: "%.0f", v)
    }

    private func materialSpecLabel(for material: QuoteDetailMaterial) -> String {
        if let yarnCount = material.yarnCount?.trimmingCharacters(in: .whitespacesAndNewlines),
           !yarnCount.isEmpty {
            return "纱支"
        }
        return "D数"
    }

    private func materialSpecValue(for material: QuoteDetailMaterial) -> String {
        if let yarnCount = material.yarnCount?.trimmingCharacters(in: .whitespacesAndNewlines),
           !yarnCount.isEmpty {
            return yarnCount
        }
        return fmtDec(material.denierNum)
    }
}

// MARK: - Reusable Section Components

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.primary)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }

            content
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

private struct DetailGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 8) {
            content
        }
    }
}

private struct DetailCell: View {
    let label: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.tertiaryText)
            Text(value ?? "-")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(2)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class QuoteDetailViewModel: ObservableObject {
    @Published var detail: QuoteDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var calcResult: CalcOutput?

    private let service = QuoteAPIService.shared

    struct CalcOutput {
        let dailyProduct: Double
        let laborCost: Double
        let warpCost: Double
        let weftCost: Double
        let warpingCost: Double
        let totalCost: Double
    }

    func load(quoteNo: String) async {
        isLoading = true
        errorMessage = nil
        do {
            detail = try await service.fetchQuoteDetail(quoteNo: quoteNo)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func runCalculation() {
        guard let d = detail else { return }

        let constants = CalculationConstants.defaultConstants
        let calcResults = CalculationResults()

        let materials = buildMaterials(from: d)
        guard !materials.isEmpty else {
            calcResult = CalcOutput(dailyProduct: 0, laborCost: 0, warpCost: 0, weftCost: 0, warpingCost: 0, totalCost: 0)
            return
        }

        let warpShrinkageFactor = 1 + (d.warpWastagePercent ?? 0) / 100.0

        var alertMsg = ""
        let success = Calculator.calculate(
            boxNumber: fmt(d.reedId),
            threading: fmt(d.fastenerRange),
            fabricWidth: fmt(d.width),
            edgeFinishing: fmt(d.sideLength),
            fabricShrinkage: String(format: "%.4f", warpShrinkageFactor),
            weftDensity: fmt(d.weftDensity),
            machineSpeed: fmt(d.weaveSpeed),
            efficiency: fmt(d.weaveEff),
            dailyLaborCost: fmt(d.weaveDaySaleCost),
            fixedCost: fmt(d.sizingPrice),
            materials: materials,
            constants: constants,
            calculationResults: calcResults,
            warpEndsOverride: d.beamTotalEnd.map { "\($0)" } ?? "",
            alertMessage: &alertMsg
        )

        if success {
            calcResult = CalcOutput(
                dailyProduct: calcResults.dailyProduct,
                laborCost: calcResults.laborCost,
                warpCost: calcResults.warpCost,
                weftCost: calcResults.weftCost,
                warpingCost: calcResults.warpingCost,
                totalCost: calcResults.totalCost
            )
        } else {
            calcResult = nil
            errorMessage = alertMsg.isEmpty ? "计算失败" : alertMsg
        }
    }

    /// Preserve each detail row's warp/weft ownership so recalculation keeps direction-specific materials separate.
    private func buildMaterials(from d: QuoteDetail) -> [Material] {
        guard let dtlMaterials = d.materials, !dtlMaterials.isEmpty else { return [] }

        var result = dtlMaterials.compactMap { materialRow -> Material? in
            let isWarp = materialRow.usage?.contains("经") == true
            let labelPrefix = isWarp ? "经纱" : "纬纱"
            let displayName = [labelPrefix, materialRow.materialName]
                .compactMap { value in
                    guard let value, !value.isEmpty else { return nil }
                    return value
                }
                .joined(separator: " · ")
            let yarnSpec = normalizedYarnSpec(for: materialRow)
            let yarnType = resolvedYarnType(for: materialRow)
            let price = resolvedMaterialPrice(for: materialRow)
            let ratio = resolvedMaterialRatio(for: materialRow)

            return Material(
                name: displayName.isEmpty ? labelPrefix : displayName,
                warpYarnValue: isWarp ? yarnSpec : "0",
                warpYarnTypeSelection: isWarp ? yarnType : .dNumber,
                weftYarnValue: isWarp ? "0" : yarnSpec,
                weftYarnTypeSelection: isWarp ? .dNumber : yarnType,
                warpYarnPrice: isWarp ? price : "0",
                weftYarnPrice: isWarp ? "0" : price,
                warpRatio: isWarp ? ratio : "0",
                weftRatio: isWarp ? "0" : ratio,
                ratio: "1"
            )
        }

        // Calculator requires totalWarpRatio > 0 AND totalWeftRatio > 0.
        // When one side is entirely missing (e.g. no warp rows), inject a tiny
        // phantom ratio on the first material. D=0 & price=0 on that side ensure
        // the phantom contributes zero cost.
        let totalWarp = result.map { Double($0.warpRatio ?? "0") ?? 0 }.reduce(0, +)
        let totalWeft = result.map { Double($0.weftRatio ?? "0") ?? 0 }.reduce(0, +)
        if totalWarp == 0 && !result.isEmpty {
            result[0].warpRatio = "0.001"
        }
        if totalWeft == 0 && !result.isEmpty {
            result[0].weftRatio = "0.001"
        }

        return result
    }

    private func resolvedYarnType(for material: QuoteDetailMaterial) -> YarnType {
        if let yarnCount = material.yarnCount?.trimmingCharacters(in: .whitespacesAndNewlines),
           !yarnCount.isEmpty,
           (material.denierNum == nil || material.denierNum == 0) {
            return .yarnCount
        }

        return .dNumber
    }

    private func normalizedYarnSpec(for material: QuoteDetailMaterial) -> String {
        switch resolvedYarnType(for: material) {
        case .dNumber:
            let value = material.denierNum ?? 0
            return String(format: "%.2f", value)
        case .yarnCount:
            let count = material.yarnCount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return count.isEmpty ? "0" : count
        }
    }

    private func resolvedMaterialPrice(for material: QuoteDetailMaterial) -> String {
        let unitPrice = material.unitPrice ?? 0
        let yarnPrice = material.yarnPrice ?? 0
        let chosenPrice = unitPrice > 0 ? unitPrice : yarnPrice
        return String(format: "%.2f", chosenPrice)
    }

    private func resolvedMaterialRatio(for material: QuoteDetailMaterial) -> String {
        let candidates = [
            material.yarnQty,
            material.yarnUseQty,
            material.orderYarnQty
        ]

        if let firstPositive = candidates.compactMap({ $0 }).first(where: { $0 > 0 }) {
            return String(format: "%.4f", firstPositive)
        }

        return "1"
    }

    private func fmt(_ v: Double?) -> String {
        guard let v else { return "0" }
        return String(format: "%.4f", v)
    }
}
