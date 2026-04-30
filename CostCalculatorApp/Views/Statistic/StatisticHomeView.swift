//
//  StatisticHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-04-29.
//

import SwiftUI
import Charts

enum TrendMetric: String, CaseIterable, Hashable {
    case active = "活跃机台"
    case length = "总产量"
}

enum TrendWindow: Int, CaseIterable, Hashable, Identifiable {
    case week = 7
    case month = 30
    case quarter = 90
    case year = 365

    var id: Int { rawValue }
    var displayName: String {
        switch self {
        case .week:    return "7 天"
        case .month:   return "30 天"
        case .quarter: return "90 天"
        case .year:    return "1 年"
        }
    }
}

struct StatisticHomeView: View {
    @State private var apiService = MachineAPIService.shared
    @State private var overview: MachineOverview?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var trendMetric: TrendMetric = .active
    @State private var trendWindow: TrendWindow = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    headerSection
                    todaySummaryCard
                    trendCard
                    bucketCard
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.bottom, 40)
            }
            .background(AppTheme.Colors.groupedBackground)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await load()
            }
            .task {
                if overview == nil { await load() }
            }
            .onChange(of: trendWindow) { _, _ in
                Task { await load() }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text("机台运行状态")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(headerSubtitle)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.Spacing.large)
    }

    private var headerSubtitle: String {
        if let serverTime = overview?.serverTime {
            return "服务器时间 \(formatServerTime(serverTime))"
        }
        return "实时车间生产数据"
    }

    // MARK: - Today

    @ViewBuilder
    private var todaySummaryCard: some View {
        if let today = overview?.today {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("今日")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                HStack(spacing: AppTheme.Spacing.medium) {
                    statBlock(value: "\(today.active)", label: "活跃机台", unit: "台")
                    Divider().frame(height: 48)
                    statBlock(
                        value: formatLength(today.totalLength),
                        label: "总产量",
                        unit: "米"
                    )
                    Divider().frame(height: 48)
                    statBlock(value: "\(today.recordCount)", label: "上报", unit: "条")
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        } else if isLoading {
            placeholderCard(height: 120)
        } else if let errorMessage {
            errorCard(message: errorMessage)
        }
    }

    private func statBlock(value: String, label: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trend

    @ViewBuilder
    private var trendCard: some View {
        if let trend = overview?.trend, !trend.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Text("最近\(trendWindow.displayName)趋势")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    Spacer()
                }

                Picker("窗口", selection: $trendWindow) {
                    ForEach(TrendWindow.allCases) { window in
                        Text(window.displayName).tag(window)
                    }
                }
                .pickerStyle(.segmented)

                Picker("指标", selection: $trendMetric) {
                    ForEach(TrendMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)

                Chart(trend) { day in
                    BarMark(
                        x: .value("日期", shortDate(day.date)),
                        y: .value(trendMetric.rawValue, trendValue(for: day))
                    )
                    .foregroundStyle(AppTheme.Colors.primary)
                    .cornerRadius(barCornerRadius)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: trendXAxisDesiredCount))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let raw = value.as(Double.self) {
                                Text(formatTrendY(raw))
                            }
                        }
                    }
                }

                HStack {
                    Image(systemName: "info.circle")
                    Text(trendCaption)
                }
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        } else if isLoading {
            placeholderCard(height: 200)
        }
    }

    private var barCornerRadius: CGFloat {
        switch trendWindow {
        case .week:    return 4
        case .month:   return 2
        case .quarter, .year: return 1
        }
    }

    private var trendXAxisDesiredCount: Int {
        switch trendWindow {
        case .week:    return 7
        case .month:   return 6
        case .quarter: return 6
        case .year:    return 6
        }
    }

    private func trendValue(for day: MachineDailyTrend) -> Double {
        switch trendMetric {
        case .active: return Double(day.activeMachines)
        case .length: return day.totalLength
        }
    }

    private var trendCaption: String {
        switch trendMetric {
        case .active: return "柱高 = 当日活跃机台数"
        case .length: return "柱高 = 当日总产量（米）"
        }
    }

    private func formatTrendY(_ value: Double) -> String {
        switch trendMetric {
        case .active:
            return String(Int(value))
        case .length:
            return value >= 10_000
                ? String(format: "%.0f万", value / 10_000)
                : String(Int(value))
        }
    }

    // MARK: - Bucket Distribution

    @ViewBuilder
    private var bucketCard: some View {
        if let counts = overview?.bucketCounts {
            VStack(alignment: .leading, spacing: 0) {
                Text("按状态分布")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(AppTheme.Spacing.medium)

                ForEach(MachineBucket.allCases, id: \.self) { bucket in
                    NavigationLink {
                        MachineListView(initialBucket: bucket)
                    } label: {
                        bucketRow(
                            bucket: bucket,
                            count: counts.count(for: bucket)
                        )
                    }
                    .buttonStyle(.plain)

                    if bucket != MachineBucket.allCases.last {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        } else if isLoading {
            placeholderCard(height: 280)
        }
    }

    private func bucketRow(bucket: MachineBucket, count: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: bucket.systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(bucket.color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(bucket.displayName)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            Text("\(count)")
                .font(.system(size: 18, weight: .light, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .contentTransition(.numericText())

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.tertiaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .contentShape(Rectangle())
    }

    // MARK: - Placeholder & Error

    private func placeholderCard(height: CGFloat) -> some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
    }

    private func errorCard(message: String) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("重试") {
                Task { await load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, AppTheme.Spacing.medium)
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            overview = try await apiService.fetchOverview(trendDays: trendWindow.rawValue)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Formatters

    private func formatLength(_ value: Double) -> String {
        if value >= 10_000 {
            return String(format: "%.1f万", value / 10_000)
        }
        return String(format: "%.0f", value)
    }

    private func shortDate(_ raw: String) -> String {
        // "2026-04-29" → "04-29"
        if raw.count >= 10 {
            return String(raw.suffix(5))
        }
        return raw
    }

    private func formatServerTime(_ raw: String) -> String {
        // "2026-04-29T16:30:00" → "04-29 16:30"
        let components = raw.split(separator: "T")
        guard components.count == 2 else { return raw }
        let date = components[0].suffix(5)
        let time = components[1].prefix(5)
        return "\(date) \(time)"
    }
}

#Preview {
    StatisticHomeView()
}
