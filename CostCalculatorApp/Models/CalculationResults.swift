//
//  CalculationResults.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation

class CalculationResults: ObservableObject {
    @Published var warpCost: Double = 0.0
    @Published var weftCost: Double = 0.0
    @Published var warpingCost: Double = 0.0
    @Published var laborCost: Double = 0.0
    @Published var totalCost: Double = 0.0
    @Published var dailyProduct: Double = 0.0
    @Published var warpWeight: Double = 0.0
    @Published var weftWeight: Double = 0.0
    
    @Published var perMaterialResults: [MaterialCalculationResult] = []
}
