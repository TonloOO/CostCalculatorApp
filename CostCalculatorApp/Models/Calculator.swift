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
        weftDensity: String,
        machineSpeed: String,
        efficiency: String,
        dailyLaborCost: String,
        fixedCost: String,
        materials: [Material],
        constants: CalculationConstants,
        calculationResults: CalculationResults,
        alertMessage: inout String
    ) -> Bool {
        
        let totalWarpRatio = materials.compactMap { Double($0.warpRatio ?? $0.ratio) }.reduce(0, +)
        let totalWeftRatio = materials.compactMap { Double($0.weftRatio ?? $0.ratio) }.reduce(0, +)
        if totalWarpRatio == 0 || totalWeftRatio == 0 {
            alertMessage = "材料比例之和不能为零。"
            return false
        }
        
        
        
        var totalWarpCost: Double = 0
        var totalWeftCost: Double = 0
        var totalWarpWeight: Double = 0
        var totalWeftWeight: Double = 0
        
        // Input validation
        guard let boxNumberValue = Double(boxNumber), boxNumberValue >= 0 else {
            alertMessage = "请输入有效的筘号。"
            return false
        }

        guard let threadingValue = Double(threading), threadingValue >= 0 else {
            alertMessage = "请输入有效的穿入值。"
            return false
        }

        guard let fabricWidthValue = Double(fabricWidth), fabricWidthValue >= 0 else {
            alertMessage = "请输入有效的门幅。"
            return false
        }

        guard let edgeFinishingValue = Double(edgeFinishing), edgeFinishingValue >= 0 else {
            alertMessage = "请输入有效的加边。"
            return false
        }
        
        // 实际门幅 = 门幅 + 加边
        let actualFabricWidth = fabricWidthValue + edgeFinishingValue
        
        guard let fabricShrinkageValue = Double(fabricShrinkage), fabricShrinkageValue >= 0 else {
            alertMessage = "请输入有效的织缩。"
            return false
        }

        guard let weftDensityValue = Double(weftDensity), weftDensityValue >= 0 else {
            alertMessage = "请输入有效的下机纬密。"
            return false
        }

        guard let machineSpeedValue = Double(machineSpeed), machineSpeedValue >= 0 else {
            alertMessage = "请输入有效的车速。"
            return false
        }

        guard let efficiencyValue = Double(efficiency), efficiencyValue >= 0 else {
            alertMessage = "请输入有效的效率。"
            return false
        }
        
        guard let laborCostValue = Double(dailyLaborCost), laborCostValue >= 0 else {
            alertMessage = "请输入有效的日工费。"
            return false
        }

        guard let fixedCostValue = Double(fixedCost), fixedCostValue >= 0 else {
            alertMessage = "请输入有效的牵经费用。"
            return false
        }
        
        calculationResults.perMaterialResults = []
        
        for material in materials {
            
            let materialwarpratio = (material.warpRatio ?? material.ratio).isEmpty ? "0" : (material.warpRatio ?? material.ratio)
            print(materialwarpratio)
            guard let materialWarpRatio = Double(materialwarpratio), materialWarpRatio >= 0 else {
                alertMessage = "请输入有效的经纱\(material.name)比例（大于等于零）。"
                return false
            }
            
            let materialweftratio = (material.weftRatio ?? material.ratio).isEmpty ? "0" : (material.weftRatio ?? material.ratio)
            guard let materialWeftRatio = Double(materialweftratio), materialWeftRatio >= 0 else {
                alertMessage = "请输入有效的纬纱\(material.name)比例（大于等于零）。"
                return false
            }
            
            let warpyarnvaluenumber = material.warpYarnValue.isEmpty ? "0" : material.warpYarnValue
            guard let warpYarnValueNumber = Double(warpyarnvaluenumber), warpYarnValueNumber >= 0 else {
                alertMessage = "请输入有效的\(material.name)\(material.warpYarnTypeSelection.rawValue)。"
                return false
            }
            
            let weftyarnvaluenumber = material.weftYarnValue.isEmpty ? "0" : material.weftYarnValue
            guard let weftYarnValueNumber = Double(weftyarnvaluenumber), weftYarnValueNumber >= 0 else {
                alertMessage = "请输入有效的\(material.name)\(material.weftYarnTypeSelection.rawValue)。"
                return false
            }
            
            let warpyarnpricevalue = material.warpYarnPrice.isEmpty ? "0" : material.warpYarnPrice
            guard let warpYarnPriceValue = Double(warpyarnpricevalue), warpYarnPriceValue >= 0 else {
                alertMessage = "请输入有效的\(material.name)经纱纱价。"
                return false
            }
            
            let weftyarnpricevalue = material.weftYarnPrice.isEmpty ? "0" : material.weftYarnPrice
            guard let weftYarnPriceValue = Double(weftyarnpricevalue), weftYarnPriceValue >= 0 else {
                alertMessage = "请输入有效的\(material.name)纬纱纱价。"
                return false
            }
            
            let warpDValue: Double
            let weftDValue: Double
            if material.warpYarnTypeSelection == .dNumber {
                warpDValue = warpYarnValueNumber
            } else {
                warpDValue = constants.defaultDValue / warpYarnValueNumber
            }
            
            if material.weftYarnTypeSelection == .dNumber {
                weftDValue = weftYarnValueNumber
            } else {
                weftDValue = constants.defaultDValue / weftYarnValueNumber
            }
            
            let warpRatioFraction = materialWarpRatio / totalWarpRatio
            
            let weftRatioFraction = materialWeftRatio / totalWeftRatio

            // Warp calculations for this material
            let warpEnds = boxNumberValue * threadingValue * actualFabricWidth
            let warpWeight = (warpEnds * warpDValue * fabricShrinkageValue) / constants.warpDivider * warpRatioFraction
            let warpCost = (warpWeight * warpYarnPriceValue) / 1000
            // Weft calculations for this material
            let weftWeight = (weftDValue * actualFabricWidth * weftDensityValue) / constants.weftDivider * weftRatioFraction
            let weftCost = (weftWeight * weftYarnPriceValue) / 1000
            // Accumulate totals
            totalWarpWeight += warpWeight
            totalWeftWeight += weftWeight
            totalWarpCost += warpCost
            totalWeftCost += weftCost
            // Create and store per-material result
            let materialResult = MaterialCalculationResult(
                material: material,
                warpWeight: warpWeight,
                weftWeight: weftWeight,
                warpCost: warpCost,
                weftCost: weftCost
            )
            calculationResults.perMaterialResults.append(materialResult)
            
        }

        calculationResults.warpWeight = totalWarpWeight
        calculationResults.weftWeight = totalWeftWeight
        calculationResults.warpCost = totalWarpCost
        calculationResults.weftCost = totalWeftCost

        
        
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

