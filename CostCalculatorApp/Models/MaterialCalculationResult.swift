//
//  MaterialCalculationResult.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-22.
//


import Foundation

struct MaterialCalculationResult: Identifiable, Codable, Hashable {
    let id = UUID()
    let material: Material
    var warpWeight: Double = 0
    var weftWeight: Double = 0
    var warpCost: Double = 0
    var weftCost: Double = 0
}
