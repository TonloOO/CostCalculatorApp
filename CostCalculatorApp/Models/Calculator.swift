//
//  Calculator.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-01.
//

import Foundation

struct Calculator {
    static func calculate(
        boxNumber: String,
        threading: String,
        fabricWidth: String,
        edgeFinishing: String,
        fabricShrinkage: String,
        warpYarnPrice: String,
        weftYarnPrice: String,
        weftDensity: String,
        machineSpeed: String,
        efficiency: String,
        dailyLaborCost: String,
        fixedCost: String,
        warpYarnValue: String,
        warpYarnTypeSelection: YarnType,
        weftYarnValue: String,
        weftYarnTypeSelection: YarnType,
        constants: CalculationConstants,
        calculationResults: CalculationResults,
        alertMessage: inout String
    ) -> Bool {
        // Input validation
        guard let boxNumberValue = Double(boxNumber), boxNumberValue > 0 else {
            alertMessage = "请输入有效的筘号。"
            return false
        }

        guard let threadingValue = Double(threading), threadingValue > 0 else {
            alertMessage = "请输入有效的穿入值。"
            return false
        }

        guard let fabricWidthValue = Double(fabricWidth), fabricWidthValue > 0 else {
            alertMessage = "请输入有效的门幅。"
            return false
        }

        guard let edgeFinishingValue = Double(edgeFinishing), edgeFinishingValue >= 0 else {
            alertMessage = "请输入有效的加边。"
            return false
        }
        
        // 实际门幅 = 门幅 + 加边
        let actualFabricWidth = fabricWidthValue + edgeFinishingValue

        guard let warpYarnValueNumber = Double(warpYarnValue), warpYarnValueNumber > 0 else {
            alertMessage = "请输入有效的\(warpYarnTypeSelection.rawValue)。"
            return false
        }
        
        guard let weftYarnValueNumber = Double(weftYarnValue), weftYarnValueNumber > 0 else {
            alertMessage = "请输入有效的\(weftYarnTypeSelection.rawValue)。"
            return false
        }

        guard let fabricShrinkageValue = Double(fabricShrinkage), fabricShrinkageValue > 0 else {
            alertMessage = "请输入有效的织缩。"
            return false
        }

        
        guard let warpYarnPriceValue = Double(warpYarnPrice), warpYarnPriceValue > 0 else {
            alertMessage = "请输入有效的经纱纱价。"
            return false
        }

        // Input validation for weftYarnPrice
        guard let weftYarnPriceValue = Double(weftYarnPrice), weftYarnPriceValue > 0 else {
            alertMessage = "请输入有效的纬纱纱价。"
            return false
        }

        guard let weftDensityValue = Double(weftDensity), weftDensityValue > 0 else {
            alertMessage = "请输入有效的下机纬密。"
            return false
        }

        guard let machineSpeedValue = Double(machineSpeed), machineSpeedValue > 0 else {
            alertMessage = "请输入有效的车速。"
            return false
        }

        guard let efficiencyValue = Double(efficiency), efficiencyValue > 0 else {
            alertMessage = "请输入有效的效率。"
            return false
        }
        
        guard let laborCostValue = Double(dailyLaborCost), laborCostValue > 0 else {
            alertMessage = "请输入有效的日工费。"
            return false
        }

        guard let fixedCostValue = Double(fixedCost), fixedCostValue >= 0 else {
            alertMessage = "请输入有效的牵经费用。"
            return false
        }

        let warpDValue: Double
        let weftDValue: Double
        if warpYarnTypeSelection == .dNumber {
            warpDValue = warpYarnValueNumber
        } else {
            warpDValue = constants.defaultDValue / warpYarnValueNumber
        }
        
        if weftYarnTypeSelection == .dNumber {
            weftDValue = weftYarnValueNumber
        } else {
            weftDValue = constants.defaultDValue / weftYarnValueNumber
        }

        // 1. Warp cost calculation
        let warpEnds = boxNumberValue * threadingValue * actualFabricWidth
        let warpCostValue = ((warpEnds * warpDValue * fabricShrinkageValue) / constants.warpDivider * warpYarnPriceValue) / 1000
        calculationResults.warpCost = warpCostValue

        // 2. Weft cost calculation
        let weftCostValue = ((weftDValue * actualFabricWidth * weftDensityValue) / constants.weftDivider * weftYarnPriceValue) / 1000
        calculationResults.weftCost = weftCostValue
        // 3. Warping cost
        calculationResults.warpingCost = fixedCostValue
        // 4. Labor cost calculation
        let dailyProduct = (machineSpeedValue * (efficiencyValue / 100) * constants.minutesPerDay) / (weftDensityValue * 100)
        calculationResults.dailyProduct = dailyProduct
        let laborValue = laborCostValue / dailyProduct
        calculationResults.laborCost = laborValue
        // 5. Total cost
        calculationResults.totalCost = calculationResults.warpCost + calculationResults.weftCost + calculationResults.warpingCost + calculationResults.laborCost

        // Calculation successful
        return true
    }
}

