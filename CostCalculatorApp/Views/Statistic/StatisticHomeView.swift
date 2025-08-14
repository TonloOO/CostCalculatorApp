//
//  StatisticHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2025-01-06.
//

import SwiftUI
import CoreData

struct StatisticHomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CalculationRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<CalculationRecord>
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        // Header
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                            Text("统计分析")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundColor(AppTheme.Colors.primaryText)
                            
                            Text("查看您的计算数据统计")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.top, AppTheme.Spacing.large)
                        
                        // Quick Stats Section
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("快速统计")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .padding(.horizontal, AppTheme.Spacing.large)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.medium) {
                                    QuickStatCard(
                                        title: "总计算次数",
                                        value: "\(records.count)",
                                        icon: "number.circle.fill",
                                        color: AppTheme.Colors.primary
                                    )
                                    
                                    QuickStatCard(
                                        title: "今日计算",
                                        value: "\(todayRecordsCount)",
                                        icon: "calendar.circle.fill",
                                        color: AppTheme.Colors.accent
                                    )
                                    
                                    QuickStatCard(
                                        title: "平均总成本",
                                        value: String(format: "¥%.2f", averageTotalCost),
                                        icon: "yensign.circle.fill",
                                        color: .green
                                    )
                                    
                                    QuickStatCard(
                                        title: "最高成本",
                                        value: String(format: "¥%.2f", maxTotalCost),
                                        icon: "arrow.up.circle.fill",
                                        color: .orange
                                    )
                                }
                                .padding(.horizontal, AppTheme.Spacing.large)
                            }
                        }
                        
                        // Monthly Statistics
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("月度统计")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .padding(.horizontal, AppTheme.Spacing.large)
                            
                            VStack(spacing: AppTheme.Spacing.small) {
                                StatisticRow(
                                    title: "本月计算次数",
                                    value: "\(currentMonthRecordsCount) 次",
                                    icon: "calendar"
                                )
                                
                                StatisticRow(
                                    title: "本月平均成本",
                                    value: String(format: "¥%.2f", currentMonthAverageCost),
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                                
                                StatisticRow(
                                    title: "本月总产量",
                                    value: String(format: "%.2f 米", currentMonthTotalProduction),
                                    icon: "ruler"
                                )
                            }
                            .padding(.horizontal, AppTheme.Spacing.large)
                        }
                        
                        // Material Statistics
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("材料使用统计")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .padding(.horizontal, AppTheme.Spacing.large)
                            
                            VStack(spacing: AppTheme.Spacing.small) {
                                StatisticRow(
                                    title: "平均经纱重量",
                                    value: String(format: "%.2f g/m", averageWarpWeight),
                                    icon: "scalemass"
                                )
                                
                                StatisticRow(
                                    title: "平均纬纱重量",
                                    value: String(format: "%.2f g/m", averageWeftWeight),
                                    icon: "scalemass"
                                )
                                
                                StatisticRow(
                                    title: "平均日产量",
                                    value: String(format: "%.2f 米/天", averageDailyProduct),
                                    icon: "timer"
                                )
                            }
                            .padding(.horizontal, AppTheme.Spacing.large)
                        }
                        
                        // Cost Breakdown
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("成本构成")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .padding(.horizontal, AppTheme.Spacing.large)
                            
                            VStack(spacing: AppTheme.Spacing.small) {
                                StatisticRow(
                                    title: "平均经纱成本",
                                    value: String(format: "¥%.2f", averageWarpCost),
                                    icon: "yensign.circle"
                                )
                                
                                StatisticRow(
                                    title: "平均纬纱成本",
                                    value: String(format: "¥%.2f", averageWeftCost),
                                    icon: "yensign.circle"
                                )
                                
                                StatisticRow(
                                    title: "平均人工成本",
                                    value: String(format: "¥%.2f", averageLaborCost),
                                    icon: "person.circle"
                                )
                                
                                StatisticRow(
                                    title: "平均牵经成本",
                                    value: String(format: "¥%.2f", averageWarpingCost),
                                    icon: "gearshape.circle"
                                )
                            }
                            .padding(.horizontal, AppTheme.Spacing.large)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayRecordsCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return records.filter { record in
            guard let date = record.date else { return false }
            return calendar.isDate(date, inSameDayAs: today)
        }.count
    }
    
    private var currentMonthRecordsCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return records.filter { record in
            guard let date = record.date else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var currentMonthRecords: [CalculationRecord] {
        let calendar = Calendar.current
        let now = Date()
        return records.filter { record in
            guard let date = record.date else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
    }
    
    private var averageTotalCost: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.totalCost }
        return sum / Double(records.count)
    }
    
    private var maxTotalCost: Double {
        records.map { $0.totalCost }.max() ?? 0
    }
    
    private var currentMonthAverageCost: Double {
        let monthRecords = currentMonthRecords
        guard !monthRecords.isEmpty else { return 0 }
        let sum = monthRecords.reduce(0) { $0 + $1.totalCost }
        return sum / Double(monthRecords.count)
    }
    
    private var currentMonthTotalProduction: Double {
        currentMonthRecords.reduce(0) { $0 + $1.dailyProduct }
    }
    
    private var averageWarpWeight: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.warpWeight }
        return sum / Double(records.count)
    }
    
    private var averageWeftWeight: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.weftWeight }
        return sum / Double(records.count)
    }
    
    private var averageDailyProduct: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.dailyProduct }
        return sum / Double(records.count)
    }
    
    private var averageWarpCost: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.warpCost }
        return sum / Double(records.count)
    }
    
    private var averageWeftCost: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.weftCost }
        return sum / Double(records.count)
    }
    
    private var averageLaborCost: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.laborCost }
        return sum / Double(records.count)
    }
    
    private var averageWarpingCost: Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.warpingCost }
        return sum / Double(records.count)
    }
}

// MARK: - Statistic Row Component
struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 30)
            
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 2, x: 0, y: 1)
    }
}

struct StatisticHomeView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticHomeView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
