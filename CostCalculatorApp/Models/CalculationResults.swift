//
//  CalculationResults.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation
import Observation

@Observable
@MainActor
final class CalculationResults {
    var warpCost: Double = 0.0
    var weftCost: Double = 0.0
    var warpingCost: Double = 0.0
    var laborCost: Double = 0.0
    var totalCost: Double = 0.0
    var dailyProduct: Double = 0.0
    var warpWeight: Double = 0.0
    var weftWeight: Double = 0.0

    var perMaterialResults: [MaterialCalculationResult] = []
}
