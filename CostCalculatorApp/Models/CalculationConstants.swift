//
//  CalculationConstants.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation

class CalculationConstants: NSObject, NSSecureCoding, Codable {
    var warpDivider: Double
    var weftDivider: Double
    var minutesPerDay: Double
    var defaultDValue: Double

    static var supportsSecureCoding: Bool {
        return true
    }

    // MARK: - NSSecureCoding
    required init?(coder: NSCoder) {
        self.warpDivider = coder.decodeDouble(forKey: "warpDivider")
        self.weftDivider = coder.decodeDouble(forKey: "weftDivider")
        self.minutesPerDay = coder.decodeDouble(forKey: "minutesPerDay")
        self.defaultDValue = coder.decodeDouble(forKey: "defaultDValue")
    }

    func encode(with coder: NSCoder) {
        coder.encode(warpDivider, forKey: "warpDivider")
        coder.encode(weftDivider, forKey: "weftDivider")
        coder.encode(minutesPerDay, forKey: "minutesPerDay")
        coder.encode(defaultDValue, forKey: "defaultDValue")
    }

    // Custom initializer
    init(warpDivider: Double, weftDivider: Double, minutesPerDay: Double, defaultDValue: Double) {
        self.warpDivider = warpDivider
        self.weftDivider = weftDivider
        self.minutesPerDay = minutesPerDay
        self.defaultDValue = defaultDValue
    }
    
    static let defaultConstants = CalculationConstants(warpDivider: 9000,
                                                       weftDivider: 9000,
                                                       minutesPerDay: 1440,
                                                       defaultDValue: 5315)
}
