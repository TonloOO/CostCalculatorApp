//
//  YarnInputField.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct YarnInputField: View {
    @Binding var yarnValue: String
    @Binding var yarnTypeSelection: YarnType
    @Binding var showPicker: Bool
    var label: String

    var body: some View {
        HStack {
            Text("\(label)规格")
                .frame(width: 80, alignment: .leading)
            TextField("", text: $yarnValue)
                .keyboardType(.decimalPad)
            Button(action: {
                showPicker.toggle()
            }) {
                HStack {
                    Text(yarnTypeSelection.rawValue)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .actionSheet(isPresented: $showPicker) {
                ActionSheet(title: Text("选择\(label)类型"), message: nil, buttons: [
                    .default(Text("D数")) {
                        yarnTypeSelection = .dNumber
                    },
                    .default(Text("支数")) {
                        yarnTypeSelection = .yarnCount
                    },
                    .cancel()
                ])
            }
        }
    }
}

