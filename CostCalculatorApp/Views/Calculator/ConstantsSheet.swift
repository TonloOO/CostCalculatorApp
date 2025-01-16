//
//  ConstantsSheet.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct ConstantsSheet: View {
    @Binding var constants: CalculationConstants
    var dismissAction: () -> Void

    @State private var warpDivider: String = ""
    @State private var weftDivider: String = ""
    @State private var minutesPerDay: String = ""
    @State private var defaultDValue: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("经纱分母")) {
                    TextField("经纱分母", text: $warpDivider)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("纬纱分母")) {
                    TextField("纬纱分母", text: $weftDivider)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("每日分钟数")) {
                    TextField("每日分钟数", text: $minutesPerDay)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("默认D数值")) {
                    TextField("默认D数值", text: $defaultDValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("修改计算常量")
            .navigationBarItems(leading: Button("取消") {
                HapticFeedbackManager.shared.selectionChanged()
                dismissAction()
            }, trailing: Button("保存") {
                HapticFeedbackManager.shared.notification(type: .success)
                saveConstants()
                dismissAction()
            }
            .disabled(!isValid()))
            .onAppear {
                warpDivider = String(constants.warpDivider)
                weftDivider = String(constants.weftDivider)
                minutesPerDay = String(constants.minutesPerDay)
                defaultDValue = String(constants.defaultDValue)
            }
        }
    }

    func saveConstants() {
        if let newWarpDivider = Double(warpDivider),
           let newWeftDivider = Double(weftDivider),
           let newMinutesPerDay = Double(minutesPerDay),
           let newDefaultDValue = Double(defaultDValue) {
            constants.warpDivider = newWarpDivider
            constants.weftDivider = newWeftDivider
            constants.minutesPerDay = newMinutesPerDay
            constants.defaultDValue = newDefaultDValue
        }
    }

    func isValid() -> Bool {
        Double(warpDivider) != nil &&
        Double(weftDivider) != nil &&
        Double(minutesPerDay) != nil &&
        Double(defaultDValue) != nil
    }
}
