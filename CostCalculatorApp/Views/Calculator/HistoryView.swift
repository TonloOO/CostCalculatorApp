//
//  HistoryView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CalculationRecord.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<CalculationRecord>
    
    @State private var searchText: String = ""
    @Environment(\.editMode) var editMode

    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    var filteredRecords: [CalculationRecord] {
        // Create the time range: from 00:00 of startDate to 23:59 of endDate
        let calendar = Calendar.current
        let adjustedStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: startDate) ?? startDate
        let adjustedEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        // Sort records by date safely
        let sortedRecords = records.sorted { (record1, record2) -> Bool in
            guard let date1 = record1.date, let date2 = record2.date else { return false }
            return date1 > date2
        }
        
        // Filter by adjusted date range
        let dateFilteredRecords = sortedRecords.filter { record in
            if let date = record.date {
                return date >= adjustedStartDate && date <= adjustedEndDate
            }
            return false
        }
        
        // Filter by search text if not empty
        if searchText.isEmpty {
            return dateFilteredRecords
        } else {
            return dateFilteredRecords.filter { record in
                if let customerName = record.customerName {
                    return fuzzyMatch(searchText: searchText, targetText: customerName)
                }
                return false
            }
        }
    }



    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("开始日期") // Custom label
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_CN")) // Set to Chinese
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("结束日期") // Custom label
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_CN")) // Set to Chinese
                }
                .padding(.horizontal)
            }

            
            List {
                if records.isEmpty {
                    Text("暂无历史记录")
                        .foregroundColor(.gray)
                } else {
                    ForEach(filteredRecords) { record in
                        NavigationLink(destination: CalculationDetailView(record: record)) {
                            VStack(alignment: .leading) {
                                Text("客户/单号：\(record.customerName!)")
                                    .font(.headline)
                                Text("计算于 \(record.date!, formatter: dateFormatter)")
                                    .font(.subheadline)
                                Text("总费用：\(record.totalCost, specifier: "%.2f") 元")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if editMode?.wrappedValue == .active {
                            editMode?.wrappedValue = .inactive
                        } else {
                            editMode?.wrappedValue = .active
                        }
                    }) {
                        Text(editMode?.wrappedValue == .active ? "完成" : "编辑")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索客户名称或单号")
        }
    }

    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            offsets.map { records[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")  // Set locale to Chinese
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"    // Custom date format in Chinese
        return formatter
    }
    
    // Custom fuzzy search function
    func fuzzyMatch(searchText: String, targetText: String) -> Bool {
        if searchText.isEmpty {
            return true
        }
        
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
