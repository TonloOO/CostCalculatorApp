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
        }
        .task {
            if viewModel.quotes.isEmpty {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Search & Filter
    
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    ForEach(QuoteStatus.allCases, id: \.rawValue) { status in
                        FilterChip(
                            title: status.label,
                            isSelected: viewModel.selectedStatus == status
                        ) {
                            viewModel.selectedStatus = status
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - List
    
    private var overviewList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.quotes) { quote in
                    QuoteOverviewCard(quote: quote)
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
            .padding(.top, AppTheme.Spacing.small)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshAsync()
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
    @State private var isExpanded = false
    @State private var showWeavePattern = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            
            Divider()
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            keyMetricsGrid
            
            if isExpanded {
                expandedContent
            }
            
            expandToggle
        }
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showWeavePattern) {
            WeavePatternView(quoteNo: quote.quoteNo)
        }
    }
    
    // MARK: - Header
    
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.quoteNo)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if let materialNo = quote.materialNo, !materialNo.isEmpty {
                        Text("产品编号: \(materialNo)")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.primary)
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
                            .foregroundColor(AppTheme.Colors.accent)
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
    
    // MARK: - Key Metrics (always visible)
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            MetricItem(label: "订单数量", value: formatNumber(quote.orderQty), icon: "shippingbox")
            MetricItem(label: "门幅", value: formatDecimal(quote.width), icon: "ruler")
            MetricItem(label: "纬密", value: formatDecimal(quote.weftDensity), icon: "lines.measurement.horizontal")
            MetricItem(label: "总经根数", value: formatInt(quote.beamTotalEnd), icon: "number")
            MetricItem(label: "日工费", value: formatPrice(quote.weaveDaySaleCost), icon: "yensign.circle")
            MetricItem(label: "日产量", value: formatDecimal(quote.weaveDayOutput), icon: "gauge.with.dots.needle.67percent")
        }
        .padding(AppTheme.Spacing.medium)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Divider()
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            if let materials = quote.materials, !materials.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("原料明细")
                        .font(AppTheme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                    
                    ForEach(materials) { material in
                        HStack {
                            Circle()
                                .fill(AppTheme.Colors.primary.opacity(0.6))
                                .frame(width: 6, height: 6)
                            
                            Text(material.materialName ?? "-")
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(AppTheme.Colors.primaryText)
                            
                            Spacer()
                            
                            if let provider = material.providerName {
                                Text(provider)
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                            }
                            
                            if let price = material.unitPrice {
                                Text(String(format: "¥%.2f", price))
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, 3)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
            }
        }
    }
    
    // MARK: - Expand Toggle
    
    private var expandToggle: some View {
        Button(action: {
            withAnimation(AppTheme.Animation.quick) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Spacer()
                
                Text(isExpanded ? "收起" : "展开详情")
                    .font(AppTheme.Typography.caption1)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
                
                Spacer()
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.vertical, AppTheme.Spacing.xSmall)
        }
    }
    
    // MARK: - Formatters
    
    private func formatPrice(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return String(format: "¥%.0f", v)
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
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.selectionChanged()
            action()
        }) {
            Text(title)
                .font(AppTheme.Typography.footnote)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.primaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.xSmall)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.Colors.primaryGradient)
                        : AnyShapeStyle(AppTheme.Colors.secondaryBackground)
                )
                .clipShape(Capsule())
        }
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

// MARK: - Mini Info (kept for potential reuse)

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

// MARK: - ViewModel

@MainActor
class QuoteOverviewViewModel: ObservableObject {
    @Published var quotes: [QuoteOverview] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: QuoteStatus = .all {
        didSet { refresh() }
    }
    @Published var searchText = ""
    
    private var currentPage = 1
    private var totalPages = 1
    private let service = QuoteAPIService.shared
    
    var hasMore: Bool { currentPage < totalPages }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.fetchQuoteOverview(
                status: selectedStatus.queryValue,
                keyword: searchText.isEmpty ? nil : searchText,
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
    
    func refresh() {
        Task { await loadData() }
    }
    
    func refreshAsync() async {
        await loadData()
    }
}

// MARK: - Approval List

struct QuoteApprovalView: View {
    @StateObject private var viewModel = QuoteApprovalViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                approvalFilterBar

                if viewModel.isLoading && viewModel.quotes.isEmpty {
                    Spacer()
                    LoadingView(message: "加载审批数据...")
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.quotes.isEmpty {
                    Spacer()
                    approvalErrorView(error)
                    Spacer()
                } else if viewModel.quotes.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "checklist",
                        title: "暂无审批数据",
                        subtitle: "当前筛选条件下没有报价记录",
                        actionTitle: "刷新",
                        action: { viewModel.refresh() }
                    )
                    Spacer()
                } else {
                    approvalList
                }
            }
        }
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

    private var approvalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                ForEach(QuoteStatus.allCases, id: \.rawValue) { status in
                    FilterChip(
                        title: status.label,
                        isSelected: viewModel.selectedStatus == status
                    ) {
                        viewModel.selectedStatus = status
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .background(AppTheme.Colors.background)
    }

    private var approvalList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(viewModel.quotes) { quote in
                    QuoteApprovalCard(
                        quote: quote,
                        isSubmitting: viewModel.processingQuoteNo == quote.quoteNo,
                        onAction: { action in
                            viewModel.execute(action: action, quote: quote)
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
            .padding(.top, AppTheme.Spacing.small)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refreshAsync()
        }
    }

    private func approvalErrorView(_ message: String) -> some View {
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

            Button(action: { viewModel.refresh() }) {
                Text("重试")
                    .primaryButton()
            }
        }
    }
}

struct QuoteApprovalCard: View {
    let quote: QuoteApproval
    let isSubmitting: Bool
    let onAction: (QuoteApprovalAction) -> Void

    @State private var isExpanded = false
    @State private var pendingAction: QuoteApprovalAction?

    private var availableActions: [QuoteApprovalAction] {
        QuoteApprovalAction.actions(for: quote.normalizedStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            approvalHeader

            Divider()
                .padding(.horizontal, AppTheme.Spacing.medium)

            approvalMetrics

            if isExpanded {
                approvalDetails
            }

            if !availableActions.isEmpty {
                Divider()
                    .padding(.horizontal, AppTheme.Spacing.medium)

                actionBar
            }

            expandToggle
        }
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        .confirmationDialog(
            pendingAction?.label ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(action.label) {
                    onAction(action)
                    pendingAction = nil
                }
            }
            Button("取消", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("确认对 \(quote.quoteNo) 执行该操作？")
        }
    }

    private var approvalHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quote.quoteNo)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)

                    if let materialName = quote.materialName, !materialName.isEmpty {
                        Text(materialName)
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }

                Spacer()

                Text(quote.status)
                    .font(AppTheme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: AppTheme.Spacing.medium) {
                if let customerName = quote.customerName, !customerName.isEmpty {
                    Label(customerName, systemImage: "building.2")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }

                if let quoteTime = quote.quoteTime, !quoteTime.isEmpty {
                    Label(quoteTime, systemImage: "calendar")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
    }

    private var approvalMetrics: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            MetricItem(label: "报价", value: formatPrice(quote.price), icon: "yensign.circle")
            MetricItem(label: "成本价", value: formatPrice(quote.costPrice), icon: "sum")
            MetricItem(label: "利润率", value: formatPercent(quote.profitRate), icon: "chart.line.uptrend.xyaxis")
            MetricItem(label: "订单数量", value: formatNumber(quote.orderQty), icon: "shippingbox")
            MetricItem(label: "门幅", value: formatDecimal(quote.width), icon: "ruler")
            MetricItem(label: "总经根数", value: formatInt(quote.beamTotalEnd), icon: "number")
        }
        .padding(AppTheme.Spacing.medium)
    }

    private var approvalDetails: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Divider()
                .padding(.horizontal, AppTheme.Spacing.medium)

            detailRow("织造日工费", formatPrice(quote.weaveDaySaleCost))
            detailRow("织价", formatPrice(quote.weavePrice))
            detailRow("浆纱价", formatPrice(quote.sizingPrice))
            detailRow("浆纱厂", quote.sizingProviderName ?? "-")
            detailRow("纱价", formatPrice(quote.yarnPrice))
            detailRow("联系人", quote.linkMan ?? "-")
            detailRow("备注", quote.remark ?? "-")
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
    }

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
            }
        }
        .padding(AppTheme.Spacing.medium)
    }

    private var expandToggle: some View {
        Button(action: {
            withAnimation(AppTheme.Animation.quick) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Spacer()

                Text(isExpanded ? "收起" : "展开详情")
                    .font(AppTheme.Typography.caption1)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))

                Spacer()
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.vertical, AppTheme.Spacing.xSmall)
        }
    }

    private var statusColor: Color {
        switch quote.normalizedStatus {
        case .editing:
            return AppTheme.Colors.warning
        case .submitted:
            return AppTheme.Colors.primary
        case .approved:
            return AppTheme.Colors.success
        case .all, .none:
            return AppTheme.Colors.tertiaryText
        }
    }

    private func actionColor(for action: QuoteApprovalAction) -> Color {
        switch action {
        case .submit:
            return AppTheme.Colors.primary
        case .approve:
            return AppTheme.Colors.success
        case .reject:
            return AppTheme.Colors.error
        case .revoke:
            return AppTheme.Colors.warning
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.tertiaryText)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.primaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 2)
    }

    private func formatPrice(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "¥%.2f", value)
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f%%", value)
    }

    private func formatDecimal(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value)
    }

    private func formatNumber(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.0f", value)
    }

    private func formatInt(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "\(value)"
    }
}

@MainActor
final class QuoteApprovalViewModel: ObservableObject {
    @Published var quotes: [QuoteApproval] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionMessage: String?
    @Published var processingQuoteNo: String?
    @Published var selectedStatus: QuoteStatus = .all {
        didSet { refresh() }
    }

    private var currentPage = 1
    private var totalPages = 1
    private let service = QuoteAPIService.shared
    private let authManager = QuoteAuthManager.shared

    var hasMore: Bool { currentPage < totalPages }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchQuoteApproval(
                status: selectedStatus.queryValue,
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
            let response = try await service.fetchQuoteApproval(
                status: selectedStatus.queryValue,
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

    func execute(action: QuoteApprovalAction, quote: QuoteApproval) {
        guard processingQuoteNo == nil else { return }
        guard let operatorName = authManager.currentUser, !operatorName.isEmpty else {
            actionMessage = "当前未登录，无法执行审批操作"
            return
        }

        processingQuoteNo = quote.quoteNo
        errorMessage = nil

        Task {
            do {
                let response = try await service.performApprovalAction(
                    quoteNo: quote.quoteNo,
                    action: action,
                    operatorName: operatorName
                )
                actionMessage = response.summaryText
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
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
}
