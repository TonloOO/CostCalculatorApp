//
//  ResultView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var calculationResults: CalculationResults
    var customerName: String
    var dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("计算结果")
                .font(.headline)
                .padding()
            Text("客户名称/单号: \(customerName)")
                .font(.subheadline)
            Group {
                Text("经纱成本：\(calculationResults.warpCost, specifier: "%.3f") 元/米")
                Text("纬纱成本：\(calculationResults.weftCost, specifier: "%.3f") 元/米")
                Text("牵经费用：\(calculationResults.warpingCost, specifier: "%.3f") 元/米")
                Text("工费：\(calculationResults.laborCost, specifier: "%.3f") 元/米")
                Text("日产量：\(calculationResults.dailyProduct, specifier: "%.3f") 米")
                Text("总费用：\(calculationResults.totalCost, specifier: "%.3f") 元/米")
                        .font(.title)  // Larger font size
                        .fontWeight(.bold)  // Bold font weight
                        .foregroundColor(.red)  // Red color for emphasis
                        .padding(.top, 10)
            }
            Spacer()
            Button("关闭") {
                dismissAction()
            }
            .padding()
        }
        .padding()
    }
}
