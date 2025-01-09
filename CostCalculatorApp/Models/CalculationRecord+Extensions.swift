//  CalculationRecord+Extensions.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-15.

import Foundation
import CoreData

extension CalculationRecord {
    var warpYarnType: YarnType {
        get {
            YarnType(rawValue: self.warpYarnTypeSelection ?? "") ?? .dNumber
        }
        set {
            self.warpYarnTypeSelection = newValue.rawValue
        }
    }

    var weftYarnType: YarnType {
        get {
            YarnType(rawValue: self.weftYarnTypeSelection ?? "") ?? .dNumber
        }
        set {
            self.weftYarnTypeSelection = newValue.rawValue
        }
    }

}
