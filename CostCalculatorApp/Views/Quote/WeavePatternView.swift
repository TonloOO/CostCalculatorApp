//
//  WeavePatternView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-09.
//

import SwiftUI

struct WeavePatternView: View {
    let quoteNo: String
    @Environment(\.dismiss) private var dismiss
    @State private var pattern: WeavePatternResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()

                if isLoading {
                    LoadingView(message: "加载织造工艺...")
                } else if let error = errorMessage {
                    errorContent(error)
                } else if let pattern {
                    patternContent(pattern)
                }
            }
            .navigationTitle("织造工艺")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .task { await loadPattern() }
    }

    // MARK: - Content

    private func patternContent(_ p: WeavePatternResponse) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                headerCard(p)

                if let ws = p.weaveStructure {
                    gridCard(title: "成品组织图", grid: ws)
                    gridRulesCard(title: "成品组织图", grid: ws)

                    if let gs = p.groundStructure, gs.grid != ws.grid {
                        gridCard(title: "地组织图", grid: gs)
                        gridRulesCard(title: "地组织图", grid: gs)
                    }
                } else if let gs = p.groundStructure {
                    gridCard(title: "成品组织图", grid: gs)
                    gridRulesCard(title: "成品组织图", grid: gs)
                }

                if let bs = p.backStructure {
                    gridCard(title: "反面组织图", grid: bs)
                    gridRulesCard(title: "反面组织图", grid: bs)
                }

                processParamsCard(p)

                if let meta = p.meta {
                    metaCard(meta)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header Card

    private func headerCard(_ p: WeavePatternResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.quoteNo)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)

                    if let name = p.materialName, !name.isEmpty {
                        Text("品名: \(name)")
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                Spacer()

                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.primaryGradient)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Grid Card

    private func gridCard(title: String, grid: WeaveGrid) -> some View {
        let layout = grid.compactERPLayout

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                Spacer()
                Text("\(layout?.width ?? grid.width) × \(layout?.height ?? grid.height)")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.Colors.secondaryBackground)
                    .clipShape(Capsule())
            }

            weaveGridView(grid)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
    }

    private func weaveGridView(_ grid: WeaveGrid) -> some View {
        let layout = grid.compactERPLayout
        let renderedGrid = layout?.grid ?? grid.grid
        let renderedWidth = layout?.width ?? grid.width
        let renderedRows = displayRows(for: renderedGrid)
        let cellSize: CGFloat = 18
        let axisWidth: CGFloat = 22
        let legendWidth: CGFloat = 56
        let headerHeight: CGFloat = 20
        let spacing: CGFloat = 1.5

        return ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        axisCell(text: "行列", width: axisWidth, height: headerHeight)

                        ForEach(1...renderedWidth, id: \.self) { column in
                            axisCell(text: "\(column)", width: cellSize, height: headerHeight)
                        }
                    }

                    ForEach(renderedRows, id: \.displayRowNumber) { row in
                        HStack(spacing: spacing) {
                            axisCell(text: "\(row.displayRowNumber)", width: axisWidth, height: cellSize)

                            ForEach(0..<renderedWidth, id: \.self) { col in
                                let filled = col < row.cells.count
                                    ? row.cells[col] == 1
                                    : false

                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(filled
                                          ? AppTheme.Colors.primary.opacity(0.38)
                                          : AppTheme.Colors.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .stroke(AppTheme.Colors.tertiaryText.opacity(0.45), lineWidth: 0.45)
                                    )
                                    .overlay(
                                        Group {
                                            if filled && col < grid.width {
                                                Text("\(col + 1)")
                                                    .font(.system(size: max(8, cellSize * 0.55), weight: .medium))
                                                    .foregroundColor(AppTheme.Colors.primaryText)
                                            }
                                        }
                                    )
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.xSmall)
                .background(AppTheme.Colors.groupedBackground)
                .cornerRadius(AppTheme.CornerRadius.small)

                if let layout, !layout.sections.isEmpty {
                    compactLegendView(
                        layout: layout,
                        cellSize: cellSize,
                        headerHeight: headerHeight,
                        spacing: spacing
                    )
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .frame(width: legendWidth)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxSmall)
        }
        .frame(height: preferredGridHeight(rowCount: renderedRows.count))
    }

    private func displayRows(for rows: [[Int]]) -> [DisplayWeaveRow] {
        rows.enumerated().reversed().map { index, row in
            DisplayWeaveRow(
                sourceRowIndex: index,
                displayRowNumber: index + 1,
                cells: row
            )
        }
    }

    private func axisCell(text: String, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.Colors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(AppTheme.Colors.tertiaryText.opacity(0.25), lineWidth: 0.5)
            )
            .overlay(
                Text(text)
                    .font(AppTheme.Typography.caption2.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            )
            .frame(width: width, height: height)
    }

    private func compactLegendView(
        layout: CompactERPWeaveLayout,
        cellSize: CGFloat,
        headerHeight: CGFloat,
        spacing: CGFloat
    ) -> some View {
        VStack(spacing: spacing) {
            Color.clear
                .frame(height: headerHeight)

            ForEach(layout.sections.reversed(), id: \.startRow) { section in
                let rowCount = section.endRow - section.startRow + 1
                VStack(spacing: 4) {
                    Text("\(section.cumulativeEndsAt)")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.primaryText)

                    Text("\(section.repeat)次")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: CGFloat(rowCount) * cellSize + CGFloat(max(rowCount - 1, 0)) * spacing)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.Colors.tertiaryText.opacity(0.35), lineWidth: 0.8)
                )
            }
        }
    }

    private func preferredGridHeight(rowCount: Int) -> CGFloat {
        let cellSize: CGFloat = 18
        let headerHeight: CGFloat = 20
        let spacing: CGFloat = 1.5
        let gridPadding = AppTheme.Spacing.xSmall * 2

        return headerHeight
            + CGFloat(rowCount) * cellSize
            + CGFloat(max(rowCount, 0)) * spacing
            + gridPadding
    }

    // MARK: - Process Params

    private func processParamsCard(_ p: WeavePatternResponse) -> some View {
        let items: [(String, String?)] = [
            ("经纱排列", p.warpPattern),
            ("纬纱排列", p.weftPattern),
            ("穿筘/穿综", p.reedDraft),
        ]

        let visible = items.filter { $0.1 != nil && !$0.1!.isEmpty }
        guard !visible.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.Colors.accent)
                        .frame(width: 8, height: 8)
                    Text("排列与穿法")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                }

                ForEach(visible, id: \.0) { label, value in
                    paramRow(label, value ?? "-")
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        )
    }

    private func gridRulesCard(title: String, grid: WeaveGrid) -> some View {
        let repeatSummary = repeatSummaryLines(for: grid)
        let colorSummary = colorSummaryLines(for: grid)

        guard !repeatSummary.isEmpty || !colorSummary.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.Colors.warning)
                        .frame(width: 8, height: 8)
                    Text("\(title)规则")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                }

                ForEach(repeatSummary, id: \.self) { summary in
                    paramRow("纬向重复", summary)
                }

                ForEach(colorSummary, id: \.self) { summary in
                    paramRow("纱线分配", summary)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Meta Card

    private func metaCard(_ meta: WeaveMeta) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 8, height: 8)
                Text("工艺参数")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: AppTheme.Spacing.small) {
                if let v = meta.artNo, !v.isEmpty {
                    MetricItem(label: "工艺编号", value: v, icon: "tag")
                }
                if let v = meta.artType, !v.isEmpty {
                    MetricItem(label: "工艺类型", value: v, icon: "gearshape.2")
                }
                if let v = meta.reedId {
                    MetricItem(label: "筘号", value: String(format: "%.1f", v), icon: "number.square")
                }
                if let v = meta.reedType, !v.isEmpty {
                    MetricItem(label: "筘入", value: v, icon: "rectangle.split.3x1")
                }
                if let v = meta.weaveSpeed {
                    MetricItem(label: "车速", value: "\(v) rpm", icon: "speedometer")
                }
                if let v = meta.weaveEfficiency {
                    MetricItem(label: "织造效率", value: String(format: "%.1f%%", v), icon: "percent")
                }
                if let v = meta.dayOutput {
                    MetricItem(label: "日产量", value: String(format: "%.2f 米", v), icon: "gauge.with.dots.needle.67percent")
                }
                if let v = meta.weftDensity, !v.isEmpty {
                    MetricItem(label: "纬密", value: v, icon: "lines.measurement.horizontal")
                }
                if let v = meta.patternCategory, !v.isEmpty {
                    MetricItem(label: "花型分类", value: v, icon: "square.on.square.squareshape.controlhandles")
                }
            }

            if let frames = meta.heddleFrames, !frames.isEmpty {
                paramRow("综框穿法", frames)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func repeatSummaryLines(for grid: WeaveGrid) -> [String] {
        grid.repeatGroups.map { group in
            "第\(group.startRow + 1)-\(group.endRow + 1)行，重复 \(group.repeat) 次"
        }
    }

    private func colorSummaryLines(for grid: WeaveGrid) -> [String] {
        grid.colorAssignments.compactMap { assignment in
            guard assignment.groupIndex < grid.repeatGroups.count else {
                return nil
            }

            let group = grid.repeatGroups[assignment.groupIndex]
            return "第\(group.startRow + 1)-\(group.endRow + 1)行使用 \(assignment.color) 纱"
        }
    }

    private func paramRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.tertiaryText)
            Text(value)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.warning)

            Text("加载失败")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)

            Text(message)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxLarge)

            Button {
                Task { await loadPattern() }
            } label: {
                Text("重试")
                    .primaryButton()
            }
        }
    }

    // MARK: - Data Loading

    private func loadPattern() async {
        isLoading = true
        errorMessage = nil

        do {
            pattern = try await QuoteAPIService.shared.fetchWeavePattern(quoteNo: quoteNo)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
