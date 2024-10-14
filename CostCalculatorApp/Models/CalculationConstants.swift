//
//  CalculationConstants.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation

struct CalculationConstants: Codable {
    var warpDivider: Double
    var weftDivider: Double
    var minutesPerDay: Double
    var defaultDValue: Double


    func toDictionary() -> [String: Double] {
        return [
            "warpDivider": warpDivider,
            "weftDivider": weftDivider,
            "minutesPerDay": minutesPerDay,
            "defaultDValue": defaultDValue
        ]
    }
    init?(from dict: [String: Double]) {
        guard let warpDivider = dict["warpDivider"],
                let weftDivider = dict["weftDivider"],
                let minutesPerDay = dict["minutesPerDay"],
                let defaultDValue = dict["defaultDValue"] else {
            return nil
        }
        self.warpDivider = warpDivider
        self.weftDivider = weftDivider
        self.minutesPerDay = minutesPerDay
        self.defaultDValue = defaultDValue
    }
    
    static let defaultConstants = CalculationConstants(warpDivider: 9000,
                                                       weftDivider: 9000,
                                                       minutesPerDay: 1440,
                                                       defaultDValue: 5315)
    
    init(
        warpDivider: Double,
        weftDivider: Double,
        minutesPerDay: Double,
        defaultDValue: Double
    ) {
        self.warpDivider = warpDivider
        self.weftDivider = weftDivider
        self.minutesPerDay = minutesPerDay
        self.defaultDValue = defaultDValue
    }
    
}
