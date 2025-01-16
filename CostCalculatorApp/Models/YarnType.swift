//
//  YarnType.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-06.
//


enum YarnType: String, CaseIterable, Identifiable, Codable, Hashable {
    case dNumber = "D数"
    case yarnCount = "支数"

    var id: String { self.rawValue }
}
