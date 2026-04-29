//
//  HistoryView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI
import CoreData

// MARK: - Time Filter
enum TimeFilter: String, CaseIterable {
    case all = "全部"
    case threeDays = "近3天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case custom = "自定义"
    
    var cutoffDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all, .custom: return nil
        case .threeDays: return calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: now))
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: now)
            let daysToMonday = (weekday == 1) ? 6 : weekday - 2
            return calendar.date(byAdding: .day, value: -daysToMonday, to: calendar.startOfDay(for: now))
        case .thisMonth: return calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        }
    }
}

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CalculationRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<CalculationRecord>
    
    @State private var searchText: String = ""
    @AppStorage("historyTimeFilter") private var selectedFilterRaw: String = TimeFilter.all.rawValue
    @AppStorage("historyCustomStart") private var customStartInterval: Double = (Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()).timeIntervalSince1970
    @AppStorage("historyCustomEnd") private var customEndInterval: Double = Date().timeIntervalSince1970
    @State private var deleteError: String?
    @State private var showDeleteError = false
    @State private var recordToEdit: CalculationRecord?
    
    private var selectedFilter: TimeFilter {
        TimeFilter(rawValue: selectedFilterRaw) ?? .all
    }
    
    private var customStartDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: customStartInterval) },
            set: { customStartInterval = $0.timeIntervalSince1970 }
        )
    }
    private var customEndDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: customEndInterval) },
            set: { customEndInterval = $0.timeIntervalSince1970 }
        )
    }

    var filteredRecords: [CalculationRecord] {
        let sortedRecords = records.sorted { (r1, r2) -> Bool in
            guard let d1 = r1.date, let d2 = r2.date else { return false }
            return d1 > d2
        }
        
        let dateFiltered: [CalculationRecord]
        if selectedFilter == .custom {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date(timeIntervalSince1970: customStartInterval))
            let endRaw = Date(timeIntervalSince1970: customEndInterval)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endRaw) ?? endRaw
            dateFiltered = sortedRecords.filter { record in
                guard let date = record.date else { return false }
                return date >= start && date <= end
            }
        } else if let cutoff = selectedFilter.cutoffDate {
            dateFiltered = sortedRecords.filter { record in
                guard let date = record.date else { return false }
                return date >= cutoff
            }
        } else {
            dateFiltered = sortedRecords
        }
        
        if searchText.isEmpty {
            return dateFiltered
        } else {
            return dateFiltered.filter { record in
                guard let name = record.customerName else { return false }
                return fuzzyMatch(searchText: searchText, targetText: name)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            
            if records.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "clock.badge.questionmark",
                    title: "暂无历史记录",
                    subtitle: "完成一次费用计算后，记录将显示在这里"
                )
                Spacer()
            } else if filteredRecords.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "未找到记录",
                    subtitle: "尝试调整筛选条件或搜索关键词"
                )
                Spacer()
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        NavigationLink(destination: CalculationDetailView(record: record)) {
                            HistoryRecordRow(record: record)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteRecord(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                recordToEdit = record
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(AppTheme.Colors.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜索客户名称或单号")
        .sheet(item: $recordToEdit) { record in
            NavigationStack {
                EditCalculationView(record: record)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") { recordToEdit = nil }
                        }
                    }
            }
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteError ?? "未知错误")
        }
    }
    
    // MARK: - Filter Bar
    @ViewBuilder
    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilterRaw = filter.rawValue
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if filter == .custom {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11))
                                }
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            }
                            .foregroundStyle(isSelected ? .white : AppTheme.Colors.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, 10)
            }
            
            if selectedFilter == .custom {
                customDateRow
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(AppTheme.Colors.secondaryBackground)
    }
    
    @ViewBuilder
    private var customDateRow: some View {
        HStack(spacing: 12) {
            customDateField(title: "从", selection: customStartDate)

            Rectangle()
                .fill(AppTheme.Colors.tertiaryText.opacity(0.3))
                .frame(width: 16, height: 1)

            customDateField(title: "至", selection: customEndDate)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func customDateField(title: String, selection: Binding<Date>) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.tertiaryText)
                .frame(width: 12, alignment: .leading)

            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deleteRecord(_ record: CalculationRecord) {
        withAnimation {
            viewContext.delete(record)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                deleteError = nsError.localizedDescription
                showDeleteError = true
            }
        }
    }
    
    private func fuzzyMatch(searchText: String, targetText: String) -> Bool {
        if searchText.isEmpty { return true }
        var searchIndex = searchText.startIndex
        var targetIndex = targetText.startIndex
        while searchIndex < searchText.endIndex && targetIndex < targetText.endIndex {
            if searchText[searchIndex] == targetText[targetIndex] {
                searchIndex = searchText.index(after: searchIndex)
            }
            targetIndex = targetText.index(after: targetIndex)
        }
        return searchIndex == searchText.endIndex
    }
}

// MARK: - History Record Row
struct HistoryRecordRow: View {
    let record: CalculationRecord
    
    private var materialType: String {
        if let data = record.materialsResult,
           let results = try? JSONDecoder().decode([MaterialCalculationResult].self, from: data) {
            if results.count == 1 && results.first?.material.name == "单材料" {
                return "单材料"
            }
            return "\(results.count)种材料"
        }
        return "单材料"
    }
    
    private var isSingleMaterial: Bool {
        materialType == "单材料"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.customerName ?? "未知")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    
                    if let date = record.date {
                        Text(date, formatter: compactDateFormatter)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                }
                
                Spacer()
                
                // Material type badge
                Text(materialType)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSingleMaterial ? AppTheme.Colors.primary : Color(hex: "FF6B6B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            isSingleMaterial
                            ? AppTheme.Colors.primary.opacity(0.1)
                            : Color(hex: "FF6B6B").opacity(0.1)
                        )
                    )
            }
            
            // Mini cost bar
            MiniCostBar(
                warpCost: record.warpCost,
                weftCost: record.weftCost,
                laborCost: record.laborCost,
                warpingCost: record.warpingCost
            )
            
            HStack {
                Text("总费用")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Spacer()
                Text(record.totalCost, format: .number.precision(.fractionLength(3)))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.accent)
                Text("元/米")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var compactDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MM-dd HH:mm"
        return f
    }
}

// MARK: - Mini Cost Bar
struct MiniCostBar: View {
    let warpCost: Double
    let weftCost: Double
    let laborCost: Double
    let warpingCost: Double
    
    private var segments: [(String, Double, Color)] {
        [
            ("经纱", warpCost, Color(hex: "5B67CA")),
            ("纬纱", weftCost, Color(hex: "FF6B6B")),
            ("工费", laborCost, Color(hex: "FFC107")),
            ("牵经", warpingCost, Color(hex: "43E97B")),
        ].filter { $0.1 > 0 }
    }
    
    private var total: Double {
        segments.reduce(0) { $0 + $1.1 }
    }
    
    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        let fraction = total > 0 ? segment.1 / total : 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(segment.2)
                            .frame(width: max(fraction * (geo.size.width - CGFloat(segments.count - 1)), 0))
                    }
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            
            HStack(spacing: 8) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    HStack(spacing: 2) {
                        Circle()
                            .fill(segment.2)
                            .frame(width: 5, height: 5)
                        Text(segment.0)
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                }
                Spacer()
            }
        }
    }
}
