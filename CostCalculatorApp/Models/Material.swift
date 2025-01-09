//
//  Material.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-21.
//


import Foundation

struct Material: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var warpYarnValue: String
    var warpYarnTypeSelection: YarnType
    var weftYarnValue: String
    var weftYarnTypeSelection: YarnType
    var warpYarnPrice: String
    var weftYarnPrice: String
    var warpRatio: String?
    var weftRatio: String?
    var ratio: String
    
    var warpYarnValueNumber: Double {
        Double(warpYarnValue) ?? 0
    }
    
    var weftYarnValueNumber: Double {
        Double(weftYarnValue) ?? 0
    }
    
    var warpYarnPriceNumber: Double {
        Double(warpYarnPrice) ?? 0
    }
    
    var weftYarnPriceNumber: Double {
        Double(weftYarnPrice) ?? 0
    }
}

