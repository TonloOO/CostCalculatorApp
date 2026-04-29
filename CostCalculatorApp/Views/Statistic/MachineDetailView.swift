//
//  MachineDetailView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-04-29.
//

import SwiftUI
import Charts

struct MachineDetailView: View {
    let equipmentNo: String

    @State private var apiService = MachineAPIService.shared
    @State private var detail: MachineDetail?
    @State private var days: Int = 14
    @State private var isLoading = false
    @State private var errorMessage: String?

    private static let dayOptions = [7, 14, 30]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                headerCard
                daysPicker
                dailyChartCard
                dailySummaryCard
                recentRecordsCard
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.top, AppTheme.Spacing.medium)
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.groupedBackground)
        .navigationTitle(equipmentNo)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task {
            if detail == nil { await load() }
        }
        .onChange(of: days) { _, _ in
            Task { await load() }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerCard: some View {
        if let detail {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(detail.bucketEnum.color)

                    Text(detail.bucketEnum.displayName)
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(detail.bucketEnum.color)
                }

                if let name = detail.equipmentName, !name.isEmpty {
                    Text(name)
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }

                if let location = detail.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                if let last = detail.lastTrackTime {
                    Label("最后上报：\(formatDateTime(last))", systemImage: "clock")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                } else {
                    Label("从未上报", systemImage: "questionmark.circle")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        } else if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
        } else if let errorMessage {
            ContentUnavailableView {
                Label("加载失败", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("重试") {
                    Task { await load() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Days picker

    private var daysPicker: some View {
        Picker("时间窗口", selection: $days) {
            ForEach(Self.dayOptions, id: \.self) { d in
                Text("\(d) 天").tag(d)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Daily chart

    @ViewBuilder
    private var dailyChartCard: some View {
        if let detail, !detail.dailySummary.isEmpty {
            let series = chartSeries(from: detail.dailySummary, days: days)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("近 \(days) 天产量")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    Spacer()
                    Text(String(format: "合计 %.0f 米", series.reduce(0) { $0 + $1.totalLength }))
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                Chart(series) { day in
                    BarMark(
                        x: .value("日期", day.date),
                        y: .value("产量", day.totalLength)
                    )
                    .foregroundStyle(
                        day.totalLength > 0
                            ? AppTheme.Colors.primary
                            : Color.gray.opacity(0.2)
                    )
                    .cornerRadius(3)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: chartXAxisDesiredCount)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.twoDigits).day(.twoDigits))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("空白柱 = 当日无落布上报（按数据库时间）")
                }
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        }
    }

    /// X-axis label density — 7d shows all, 14d every other, 30d ~6 ticks.
    private var chartXAxisDesiredCount: Int {
        switch days {
        case ...7:  return 7
        case ...14: return 7
        default:    return 6
        }
    }

    /// Build a complete day-by-day series from the API daily summary, filling
    /// missing days with zero so idle gaps are visually obvious.
    private func chartSeries(from summary: [MachineDailySummary], days: Int) -> [ChartDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        var lookup: [Date: Double] = [:]
        for item in summary {
            if let parsed = inputFormatter.date(from: item.date) {
                let key = calendar.startOfDay(for: parsed)
                lookup[key] = item.totalLength
            }
        }

        var result: [ChartDay] = []
        result.reserveCapacity(days)
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append(ChartDay(date: date, totalLength: lookup[date] ?? 0))
        }
        return result
    }

    // MARK: - Daily summary

    @ViewBuilder
    private var dailySummaryCard: some View {
        if let detail {
            VStack(alignment: .leading, spacing: 0) {
                Text("日汇总")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(AppTheme.Spacing.medium)

                if detail.dailySummary.isEmpty {
                    Text("近 \(days) 天无落布上报")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.medium)
                } else {
                    ForEach(detail.dailySummary) { day in
                        dailyRow(day: day)
                        if day.id != detail.dailySummary.last?.id {
                            Divider().padding(.leading, AppTheme.Spacing.medium)
                        }
                    }
                }
            }
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        }
    }

    private func dailyRow(day: MachineDailySummary) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.date)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                if !day.workerGroups.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(day.workerGroups, id: \.self) { group in
                            Text(group)
                                .font(AppTheme.Typography.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.primary.opacity(0.12))
                                .foregroundStyle(AppTheme.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f 米", day.totalLength))
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text("\(day.recordCount) 条")
                    .font(AppTheme.Typography.caption2)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
    }

    // MARK: - Recent records

    @ViewBuilder
    private var recentRecordsCard: some View {
        if let detail, !detail.recentRecords.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("最近落布（最多 50 条）")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(AppTheme.Spacing.medium)

                ForEach(detail.recentRecords) { record in
                    recordRow(record: record)
                    if record.id != detail.recentRecords.last?.id {
                        Divider().padding(.leading, AppTheme.Spacing.medium)
                    }
                }
            }
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
        }
    }

    private func recordRow(record: MachineRecord) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDateTime(record.trackTime))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                HStack(spacing: 4) {
                    if let fabric = record.fabricNo, !fabric.isEmpty {
                        Text(fabric)
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                    if let group = record.workerGroup, !group.isEmpty {
                        Text("· \(group)")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                    if let worker = record.workerNo, !worker.isEmpty {
                        Text("· \(worker)")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                }
            }

            Spacer()

            if let length = record.length {
                Text(String(format: "%.1f 米", length))
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            detail = try await apiService.fetchDetail(equipmentNo: equipmentNo, days: days)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Formatters

    private func formatDateTime(_ raw: String) -> String {
        let parts = raw.split(separator: "T")
        guard parts.count == 2 else { return raw }
        return "\(parts[0]) \(parts[1].prefix(5))"
    }
}

private struct ChartDay: Identifiable {
    let date: Date
    let totalLength: Double
    var id: Date { date }
}

#Preview {
    NavigationStack {
        MachineDetailView(equipmentNo: "8343")
    }
}
