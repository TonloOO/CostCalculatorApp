//
//  HistoryView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var calculationHistory: CalculationHistory
    @State private var searchText: String = ""
    @Environment(\.editMode) var editMode

    var filteredRecords: [CalculationRecord] {
        let sortedRecords = calculationHistory.records.sorted(by: { $0.date > $1.date })
        
        if searchText.isEmpty {
            return sortedRecords
        } else {
            return sortedRecords.filter { record in
                record.customerName.lowercased().contains(searchText.lowercased())
            }
        }
    }


    var body: some View {
        List {
            if calculationHistory.records.isEmpty {
                Text("暂无历史记录")
                    .foregroundColor(.gray)
            } else {
                ForEach(filteredRecords) { record in
                    NavigationLink(destination: CalculationDetailView(record: record)) {
                        VStack(alignment: .leading) {
                            Text("客户/单号：\(record.customerName)")
                                .font(.headline)
                            Text("计算于 \(record.date, formatter: dateFormatter)")
                                .font(.subheadline)
                            Text("总费用：\(record.totalCost, specifier: "%.2f") 元")
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
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

    func deleteRecord(at offsets: IndexSet) {
        // Get the records to delete from the filtered list
        let recordsToDelete = offsets.map { filteredRecords[$0] }

        // Remove each record from the original array
        for record in recordsToDelete {
            if calculationHistory.records.firstIndex(where: { $0.id == record.id }) != nil {
                calculationHistory.deleteRecord(record)
            }
        }
    }


    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")  // Set locale to Chinese
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"    // Custom date format in Chinese
        return formatter
    }

}
