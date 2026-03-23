//
//  QuoteOverviewView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct QuoteOverviewView: View {
    @StateObject private var viewModel = QuoteOverviewViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchAndFilterBar

                if let label = viewModel.dateRangeLabel {
                    activeDateBadge(label)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.top, AppTheme.Spacing.xSmall)
                        .padding(.bottom, AppTheme.Spacing.small)
                }

                if viewModel.isLoading && viewModel.quotes.isEmpty {
                    Spacer()
                    LoadingView(message: "加载报价数据...")
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.quotes.isEmpty {
                    Spacer()
                    errorView(error)
                    Spacer()
                } else if viewModel.quotes.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "暂无报价数据",
                        subtitle: "当前筛选条件下没有报价记录",
                        actionTitle: "刷新",
                        action: { viewModel.refresh() }
                    )
                    Spacer()
                } else {
                    overviewList
                }
            }

            if viewModel.isLoading, !viewModel.quotes.isEmpty {
                loadingOverlay
            }
        }
        .disabled(viewModel.isLoading && !viewModel.quotes.isEmpty)
        .task {
            if viewModel.quotes.isEmpty {
                await viewModel.loadData()
            }
        }
        .alert("操作结果", isPresented: Binding(
            get: { viewModel.actionMessage != nil },
            set: { if !$0 { viewModel.actionMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.actionMessage ?? "")
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.06)
                .ignoresSafeArea()

            HStack(spacing: AppTheme.Spacing.small) {
                ProgressView()
                    .tint(AppTheme.Colors.primary)

                Text("加载中...")
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppTheme.Colors.shadow, radius: 8, x: 0, y: 4)
        }
        .transition(.opacity)
    }
    
    // MARK: - Search & Filter

    @State private var showCustomDatePicker = false

    private var searchAndFilterBar: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.tertiaryText)

                TextField("搜索编号 / 客户 / 品名 / 原料", text: $viewModel.searchText)
                    .font(AppTheme.Typography.subheadline)
                    .onSubmit { viewModel.refresh() }

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                        viewModel.refresh()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
            }
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
            .padding(.horizontal, AppTheme.Spacing.medium)

            // Status chips + date icon
            HStack(spacing: 6) {
                ForEach(QuoteStatus.allCases, id: \.rawValue) { status in
                    FilterChip(
                        title: status.label,
                        isSelected: viewModel.selectedStatus == status
                    ) {
                        viewModel.selectedStatus = status
                    }
                    .frame(maxWidth: .infinity)
                }

                dateFilterIcon
            }
            .padding(.horizontal, AppTheme.Spacing.medium)

        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.background)
        .allowsHitTesting(!(viewModel.isLoading && !viewModel.quotes.isEmpty))
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangeSheet(viewModel: viewModel)
        }
    }

    // MARK: - Date Filter Icon (fixed size, never changes width)

    private var dateFilterIcon: some View {
        Menu {
            Button("近7天") { viewModel.applyDateRange(days: 7) }
            Button("近30天") { viewModel.applyDateRange(days: 30) }
            Button("近90天") { viewModel.applyDateRange(days: 90) }
            Button("今年") { viewModel.applyDateRangeThisYear() }
            Divider()
            Button("自选时间段") { showCustomDatePicker = true }
            if viewModel.dateFrom != nil {
                Divider()
                Button("清除筛选", role: .destructive) { viewModel.clearDateRange() }
            }
        } label: {
            Image(systemName: viewModel.dateFrom != nil ? "calendar.badge.checkmark" : "calendar.badge.clock")
                .font(.system(size: 15))
                .foregroundColor(viewModel.dateFrom != nil ? .white : AppTheme.Colors.primaryText)
                .frame(width: 34, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(viewModel.dateFrom != nil ? AppTheme.Colors.primary : AppTheme.Colors.secondaryBackground)
                )
        }
    }

    // MARK: - Active Date Badge

    private func activeDateBadge(_ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
            Text(label)
                .font(AppTheme.Typography.caption1)

            Spacer()

            Menu {
                Button("近7天") { viewModel.applyDateRange(days: 7) }
                Button("近30天") { viewModel.applyDateRange(days: 30) }
                Button("近90天") { viewModel.applyDateRange(days: 90) }
                Button("今年") { viewModel.applyDateRangeThisYear() }
                Divider()
                Button("自选时间段") { showCustomDatePicker = true }
            } label: {
                Text("修改")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.primary)
            }

            Button {
                viewModel.clearDateRange()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
        }
        .foregroundColor(AppTheme.Colors.primary)
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.Colors.primary.opacity(0.08))
        )
    }
    
    // MARK: - List
    
    private var overviewList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    Color.clear.frame(height: AppTheme.Spacing.small).id("list-top")

                    ForEach(viewModel.quotes) { quote in
                        QuoteOverviewCard(
                            quote: quote,
                            isSubmitting: viewModel.processingQuoteNo == quote.quoteNo,
                            canApprove: viewModel.authManager.canApprove,
                            onDetailUpdated: {
                                viewModel.refresh()
                            },
                            onAction: { action in
                                viewModel.execute(action: action, quoteNo: quote.quoteNo)
                            }
                        )
                    }
                    
                    if viewModel.hasMore {
                        ProgressView()
                            .padding()
                            .task {
                                await viewModel.loadMore()
                            }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.refreshAsync()
            }
            .onChange(of: viewModel.scrollResetToken) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("list-top", anchor: .top)
                }
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.warning)
            
            Text("连接失败")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Text(message)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxLarge)
            
            Button(action: { viewModel.refresh() }) {
                Text("重试")
                    .primaryButton()
            }
        }
    }
}

// MARK: - Overview Card

struct QuoteOverviewCard: View {
    let quote: QuoteOverview
    let isSubmitting: Bool
    let canApprove: Bool
    let onDetailUpdated: () -> Void
    let onAction: (QuoteApprovalAction) -> Void

    @State private var showWeavePattern = false
    @State private var showDetail = false
    @State private var pendingAction: QuoteApprovalAction?

    private var availableActions: [QuoteApprovalAction] {
        guard canApprove else { return [] }
        return QuoteApprovalAction.actions(for: quote.normalizedStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            
            Divider()
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            keyMetricsGrid

            expandedContent

            if !availableActions.isEmpty {
                Divider()
                    .padding(.horizontal, AppTheme.Spacing.medium)
                actionBar
            }
        }
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .clipped()
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showWeavePattern) {
            WeavePatternView(quoteNo: quote.quoteNo)
        }
        .sheet(isPresented: $showDetail) {
            QuoteDetailView(quoteNo: quote.quoteNo, onUpdated: onDetailUpdated)
        }
    }
    
    // MARK: - Header
    
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.materialNo ?? "-")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if let materialName = quote.materialName, !materialName.isEmpty {
                        Text(materialName)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    } else {
                        Text(" ")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(.clear)
                    }
                }
                
                Spacer()

                Button {
                    showWeavePattern = true
                } label: {
                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.primaryGradient)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                if let price = quote.price {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("报价")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                        Text(String(format: "¥%.2f", price))
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.bold)
                    }
                }
            }
            
            HStack(spacing: AppTheme.Spacing.medium) {
                if let customer = quote.customerName {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: 11))
                        Text(customer)
                            .font(AppTheme.Typography.footnote)
                    }
                    .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                if let quoteTime = quote.quoteTime, !quoteTime.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(quoteTime)
                            .font(AppTheme.Typography.footnote)
                    }
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    // MARK: - Key Metrics
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            MetricItem(label: "订单数量", value: formatNumber(quote.orderQty), icon: "shippingbox")
            MetricItem(label: "成品门幅(存档)", value: formatDecimal(quote.width), icon: "ruler")
            MetricItem(label: "纬密", value: formatDecimal(quote.weftDensity), icon: "lines.measurement.horizontal")
            MetricItem(label: "总经根数", value: formatInt(quote.beamTotalEnd), icon: "number")
            MetricItem(label: "成本价", value: formatPrice(quote.costPrice), icon: "sum")
            MetricItem(label: "利润率", value: formatPercent(quote.profitRate), icon: "chart.line.uptrend.xyaxis")
            MetricItem(label: "日工费", value: formatPrice(quote.weaveDaySaleCost), icon: "yensign.circle")
            MetricItem(label: "日产量", value: formatDecimal(quote.weaveDayOutput), icon: "gauge.with.dots.needle.67percent")
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        guard let materials = quote.materials, !materials.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Divider()
                    .padding(.horizontal, AppTheme.Spacing.medium)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("原料明细")
                        .font(AppTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .padding(.horizontal, AppTheme.Spacing.medium)

                    ForEach(materials) { material in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                usageBadge(material.usage)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(material.materialName ?? "-")
                                        .font(AppTheme.Typography.footnote)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppTheme.Colors.primaryText)

                                    if let provider = material.providerName, !provider.isEmpty {
                                        Text(provider)
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundColor(AppTheme.Colors.tertiaryText)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    if let yarnUseQty = material.yarnUseQty {
                                        Text(String(format: "用纱量 %.2f", yarnUseQty))
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundColor(AppTheme.Colors.secondaryText)
                                    }

                                    if let price = material.unitPrice {
                                        Text(String(format: "原料单价 ¥%.2f", price))
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundColor(AppTheme.Colors.secondaryText)
                                            .fontWeight(.medium)
                                    }

                                    Text(materialCostText(material.dtlYarnCost))
                                        .font(AppTheme.Typography.caption2)
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
            }
        )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(availableActions, id: \.rawValue) { action in
                Button {
                    pendingAction = action
                } label: {
                    HStack(spacing: 6) {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.75)
                                .tint(.white)
                        }
                        Text(action.label)
                            .font(AppTheme.Typography.footnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(actionColor(for: action))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .disabled(isSubmitting)
                .confirmationDialog(
                    action.label,
                    isPresented: Binding(
                        get: { pendingAction == action },
                        set: { isPresented in
                            if !isPresented, pendingAction == action {
                                pendingAction = nil
                            }
                        }
                    ),
                    titleVisibility: .visible
                ) {
                    Button(action.label) {
                        onAction(action)
                        pendingAction = nil
                    }
                    Button("取消", role: .cancel) {
                        pendingAction = nil
                    }
                } message: {
                    Text("确认对 \(quote.quoteNo) 执行该操作？")
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    // MARK: - Helpers

    @ViewBuilder
    private func usageBadge(_ usage: String?) -> some View {
        let isWarp = isWarpUsage(usage)
        let usageLabel = normalizedUsageLabel(usage)

        if let usageLabel {
            Text(usageLabel)
                .font(AppTheme.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(isWarp ? AppTheme.Colors.primary : AppTheme.Colors.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (isWarp ? AppTheme.Colors.primary : AppTheme.Colors.accent).opacity(0.12)
                )
                .cornerRadius(4)
        } else {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.6))
                .frame(width: 6, height: 6)
        }
    }

    private func materialCostText(_ value: Double?) -> String {
        guard let value else { return "原料成本 -" }
        return String(format: "原料成本 ¥%.2f", value)
    }

    private func isWarpUsage(_ usage: String?) -> Bool {
        guard let normalized = usage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !normalized.isEmpty else {
            return false
        }

        if normalized == "j" {
            return true
        }
        if normalized == "w" {
            return false
        }

        let warpMarkers = ["经", "warp"]
        let weftMarkers = ["纬", "weft"]

        if warpMarkers.contains(where: { normalized.contains($0) }) {
            return true
        }
        if weftMarkers.contains(where: { normalized.contains($0) }) {
            return false
        }

        return false
    }

    private func normalizedUsageLabel(_ usage: String?) -> String? {
        guard let normalized = usage?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return nil
        }

        return isWarpUsage(normalized) ? "经纱" : "纬纱"
    }

    private func actionColor(for action: QuoteApprovalAction) -> Color {
        switch action {
        case .submit:  return AppTheme.Colors.primary
        case .approve: return AppTheme.Colors.success
        case .reject:  return AppTheme.Colors.error
        case .revoke:  return AppTheme.Colors.warning
        }
    }
    
    private func formatPrice(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "¥%.2f", v)
    }

    
    private func formatDecimal(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "%.1f", v)
    }
    
    private func formatNumber(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "%.0f", v)
    }
    
    private func formatInt(_ value: Int?) -> String {
        guard let v = value else { return "-" }
        return "\(v)"
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "%.1f%%", v)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @GestureState private var isPressed = false

    private let chipRadius: CGFloat = 100

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.footnote)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : AppTheme.Colors.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                    .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.secondaryBackground)
            )
            .opacity(isPressed ? 0.7 : 1)
            .contentShape(RoundedRectangle(cornerRadius: chipRadius, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
                    .onEnded { _ in
                        HapticFeedbackManager.shared.selectionChanged()
                        action()
                    }
            )
    }
}

// MARK: - Metric Item

struct MetricItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.primary.opacity(0.7))
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .lineLimit(1)
                
                Text(value)
                    .font(AppTheme.Typography.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MiniInfo

struct MiniInfo: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.tertiaryText)
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
}

// MARK: - Custom Date Range Sheet

struct CustomDateRangeSheet: View {
    @ObservedObject var viewModel: QuoteOverviewViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("选择时间范围") {
                    DatePicker("起始日期", selection: $startDate, in: ...endDate, displayedComponents: .date)
                    DatePicker("截止日期", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Button("近30天") {
                            endDate = Date()
                            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
                        }
                        .buttonStyle(.bordered)

                        Button("近90天") {
                            endDate = Date()
                            startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!
                        }
                        .buttonStyle(.bordered)

                        Button("今年") {
                            endDate = Date()
                            let year = Calendar.current.component(.year, from: endDate)
                            startDate = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("自选时间段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        viewModel.applyCustomDateRange(from: startDate, to: endDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let from = viewModel.dateFrom,
                   let d = QuoteOverviewViewModel.dateFmt.date(from: from) {
                    startDate = d
                }
                if let to = viewModel.dateTo,
                   let d = QuoteOverviewViewModel.dateFmt.date(from: to) {
                    endDate = d
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(.systemBackground))
    }
}

// MARK: - ViewModel

@MainActor
class QuoteOverviewViewModel: ObservableObject {
    @Published var quotes: [QuoteOverview] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: QuoteStatus = .all {
        didSet { scrollResetToken = UUID(); refresh() }
    }
    @Published var scrollResetToken = UUID()
    @Published var searchText = ""
    @Published var processingQuoteNo: String?
    @Published var actionMessage: String?
    @Published var dateFrom: String?
    @Published var dateTo: String?
    @Published var dateRangeLabel: String?
    
    private var currentPage = 1
    private var totalPages = 1
    private let service = QuoteAPIService.shared
    let authManager = QuoteAuthManager.shared
    
    var hasMore: Bool { currentPage < totalPages }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.fetchQuoteOverview(
                status: selectedStatus.queryValue,
                keyword: searchText.isEmpty ? nil : searchText,
                dateFrom: dateFrom,
                dateTo: dateTo,
                page: 1
            )
            quotes = response.data
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        
        do {
            let response = try await service.fetchQuoteOverview(
                status: selectedStatus.queryValue,
                keyword: searchText.isEmpty ? nil : searchText,
                dateFrom: dateFrom,
                dateTo: dateTo,
                page: currentPage + 1
            )
            quotes.append(contentsOf: response.data)
            currentPage = response.page
            totalPages = response.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func execute(action: QuoteApprovalAction, quoteNo: String) {
        guard processingQuoteNo == nil else { return }
        guard let operatorName = authManager.currentUser, !operatorName.isEmpty else {
            actionMessage = "当前未登录，无法执行审批操作"
            return
        }

        processingQuoteNo = quoteNo
        errorMessage = nil

        Task {
            do {
                let response = try await service.performApprovalAction(
                    quoteNo: quoteNo,
                    action: action,
                    operatorName: operatorName
                )
                actionMessage = response.summaryText
                await loadData()
            } catch {
                actionMessage = error.localizedDescription
            }
            processingQuoteNo = nil
        }
    }
    
    func refresh() {
        Task { await loadData() }
    }
    
    func refreshAsync() async {
        await loadData()
    }

    // MARK: - Date Range

    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let shortFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yy/M/d"
        return f
    }()

    func applyDateRange(days: Int) {
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -days, to: to)!
        dateFrom = Self.dateFmt.string(from: from)
        dateTo = Self.dateFmt.string(from: to)
        dateRangeLabel = "近\(days)天"
        scrollResetToken = UUID()
        refresh()
    }

    func applyDateRangeThisYear() {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        dateFrom = "\(year)-01-01"
        dateTo = Self.dateFmt.string(from: now)
        dateRangeLabel = "\(year)年"
        scrollResetToken = UUID()
        refresh()
    }

    func applyCustomDateRange(from: Date, to: Date) {
        dateFrom = Self.dateFmt.string(from: from)
        dateTo = Self.dateFmt.string(from: to)
        dateRangeLabel = "\(Self.shortFmt.string(from: from))~\(Self.shortFmt.string(from: to))"
        scrollResetToken = UUID()
        refresh()
    }

    func clearDateRange() {
        dateFrom = nil
        dateTo = nil
        dateRangeLabel = nil
        scrollResetToken = UUID()
        refresh()
    }
}
