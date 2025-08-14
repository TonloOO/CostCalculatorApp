//
//  Calculator.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-01.
//

import Foundation

struct Calculator {
    
    // MARK: - Error Types
    enum CalculationError: LocalizedError {
        case materialValidationFailed(String)
        case materialCalculationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .materialValidationFailed(let message):
                return message
            case .materialCalculationFailed(let message):
                return message
            }
        }
    }
    
    // MARK: - Main Calculation Function
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
        useDirectWarpWeight: Bool = false,
        directWarpWeight: String = "",
        useDirectWeftWeight: Bool = false,
        directWeftWeight: String = "",
        alertMessage: inout String
    ) -> Bool {
        
        // Validate material ratios
        let ratioValidation = InputValidator.validateMaterialRatios(materials)
        if case .failure(let message) = ratioValidation {
            alertMessage = message
            return false
        }
        
        // Validate basic inputs
        let basicValidation = InputValidator.validateBasicInputsWithWeightSwitches(
            boxNumber: boxNumber,
            threading: threading,
            fabricWidth: fabricWidth,
            edgeFinishing: edgeFinishing,
            fabricShrinkage: fabricShrinkage,
            weftDensity: weftDensity,
            machineSpeed: machineSpeed,
            efficiency: efficiency,
            dailyLaborCost: dailyLaborCost,
            fixedCost: fixedCost,
            useDirectWarpWeight: useDirectWarpWeight,
            directWarpWeight: directWarpWeight,
            useDirectWeftWeight: useDirectWeftWeight,
            directWeftWeight: directWeftWeight
        )
        if case .failure(let message) = basicValidation {
            alertMessage = message
            return false
        }
        
        // Extract validated values
        guard let validatedValues = extractValidatedValues(
            boxNumber: boxNumber,
            threading: threading,
            fabricWidth: fabricWidth,
            edgeFinishing: edgeFinishing,
            fabricShrinkage: fabricShrinkage,
            weftDensity: weftDensity,
            machineSpeed: machineSpeed,
            efficiency: efficiency,
            dailyLaborCost: dailyLaborCost,
            fixedCost: fixedCost,
            useDirectWarpWeight: useDirectWarpWeight,
            useDirectWeftWeight: useDirectWeftWeight
        ) else {
            alertMessage = "输入验证失败。"
            return false
        }
        
        // Calculate material costs
        let materialCalculationResult = calculateMaterialCosts(
            materials: materials,
            validatedValues: validatedValues,
            constants: constants,
            useDirectWarpWeight: useDirectWarpWeight,
            directWarpWeight: directWarpWeight,
            useDirectWeftWeight: useDirectWeftWeight,
            directWeftWeight: directWeftWeight,
            alertMessage: &alertMessage
        )
        
        if case .failure(let error) = materialCalculationResult {
            alertMessage = error.localizedDescription
            return false
        }
        
        guard case .success(let materialResults) = materialCalculationResult else {
            alertMessage = "材料计算失败。"
            return false
        }
        
        // Update calculation results
        updateCalculationResults(
            calculationResults: calculationResults,
            materialResults: materialResults,
            validatedValues: validatedValues,
            constants: constants
        )
        
        return true
    }
    
    // MARK: - Helper Structures
    private struct ValidatedValues {
        let boxNumber: Double
        let threading: Double
        let fabricWidth: Double
        let edgeFinishing: Double
        let fabricShrinkage: Double
        let weftDensity: Double
        let machineSpeed: Double
        let efficiency: Double
        let dailyLaborCost: Double
        let fixedCost: Double
        
        var actualFabricWidth: Double {
            fabricWidth + edgeFinishing
        }
    }
    
    private struct MaterialCalculationResults {
        let totalWarpWeight: Double
        let totalWeftWeight: Double
        let totalWarpCost: Double
        let totalWeftCost: Double
        let perMaterialResults: [MaterialCalculationResult]
    }
    
    // MARK: - Private Helper Functions
    private static func extractValidatedValues(
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
        useDirectWarpWeight: Bool = false,
        useDirectWeftWeight: Bool = false
    ) -> ValidatedValues? {
        
        // Always required values
        guard let machineSpeedValue = Double(machineSpeed),
              let efficiencyValue = Double(efficiency),
              let laborCostValue = Double(dailyLaborCost),
              let fixedCostValue = Double(fixedCost) else {
            return nil
        }
        
        // Conditionally required values based on weight switches
        var boxNumberValue: Double = 0
        var threadingValue: Double = 0
        var fabricWidthValue: Double = 0
        var edgeFinishingValue: Double = 0
        var fabricShrinkageValue: Double = 0
        var weftDensityValue: Double = 0
        
        // Warp-related values (only needed if not using direct warp weight)
        if !useDirectWarpWeight {
            guard let boxNum = Double(boxNumber.isEmpty ? "0" : boxNumber),
                  let threadingNum = Double(threading.isEmpty ? "0" : threading),
                  let fabricWidthNum = Double(fabricWidth.isEmpty ? "0" : fabricWidth),
                  let edgeFinishingNum = Double(edgeFinishing.isEmpty ? "0" : edgeFinishing),
                  let fabricShrinkageNum = Double(fabricShrinkage.isEmpty ? "0" : fabricShrinkage) else {
                return nil
            }
            boxNumberValue = boxNum
            threadingValue = threadingNum
            fabricWidthValue = fabricWidthNum
            edgeFinishingValue = edgeFinishingNum
            fabricShrinkageValue = fabricShrinkageNum
        } else {
            // Still need fabric width and edge finishing if not using direct weft weight
            if !useDirectWeftWeight {
                guard let fabricWidthNum = Double(fabricWidth.isEmpty ? "0" : fabricWidth),
                      let edgeFinishingNum = Double(edgeFinishing.isEmpty ? "0" : edgeFinishing) else {
                    return nil
                }
                fabricWidthValue = fabricWidthNum
                edgeFinishingValue = edgeFinishingNum
            }
        }
        
        // Weft-related values (only needed if not using direct weft weight)
        // Weft density is always required (even when using direct weft weight) for daily production/labor cost
        guard let weftDensityNum = Double(weftDensity.isEmpty ? "0" : weftDensity) else {
            return nil
        }
        weftDensityValue = weftDensityNum
        
        return ValidatedValues(
            boxNumber: boxNumberValue,
            threading: threadingValue,
            fabricWidth: fabricWidthValue,
            edgeFinishing: edgeFinishingValue,
            fabricShrinkage: fabricShrinkageValue,
            weftDensity: weftDensityValue,
            machineSpeed: machineSpeedValue,
            efficiency: efficiencyValue,
            dailyLaborCost: laborCostValue,
            fixedCost: fixedCostValue
        )
    }
    
    private static func calculateMaterialCosts(
        materials: [Material],
        validatedValues: ValidatedValues,
        constants: CalculationConstants,
        useDirectWarpWeight: Bool,
        directWarpWeight: String,
        useDirectWeftWeight: Bool,
        directWeftWeight: String,
        alertMessage: inout String
    ) -> Result<MaterialCalculationResults, CalculationError> {
        
        var totalWarpCost: Double = 0
        var totalWeftCost: Double = 0
        var totalWarpWeight: Double = 0
        var totalWeftWeight: Double = 0
        var perMaterialResults: [MaterialCalculationResult] = []
        
        // Handle direct weight calculations
        if useDirectWarpWeight && useDirectWeftWeight {
            // Both weights are directly provided
            guard let directWarpWeightValue = Double(directWarpWeight),
                  let directWeftWeightValue = Double(directWeftWeight) else {
                return .failure(.materialCalculationFailed("直接输入的重量值无效。"))
            }
            
            totalWarpWeight = directWarpWeightValue
            totalWeftWeight = directWeftWeightValue
            
            // Calculate costs based on direct weights
            // Direction-specific totals only (no fallback to generic ratio)
            let totalWarpRatio = materials.map { Double($0.warpRatio ?? "0") ?? 0 }.reduce(0, +)
            let totalWeftRatio = materials.map { Double($0.weftRatio ?? "0") ?? 0 }.reduce(0, +)
            
            for material in materials {
                // Validate material even when using direct weights, to enforce ratios and prices
                let materialValidation = InputValidator.validateMaterial(
                    material,
                    useDirectWarpWeight: true,
                    useDirectWeftWeight: true
                )
                if case .failure(let message) = materialValidation {
                    return .failure(.materialValidationFailed(message))
                }
                let materialWarpRatio = Double(material.warpRatio ?? "0") ?? 0
                let materialWeftRatio = Double(material.weftRatio ?? "0") ?? 0
                let warpYarnPriceValue = Double(material.warpYarnPrice) ?? 0
                let weftYarnPriceValue = Double(material.weftYarnPrice) ?? 0
                
                let materialWarpWeight = directWarpWeightValue * (materialWarpRatio / totalWarpRatio)
                let materialWeftWeight = directWeftWeightValue * (materialWeftRatio / totalWeftRatio)
                
                let warpCost = (materialWarpWeight * warpYarnPriceValue) / 1000
                let weftCost = (materialWeftWeight * weftYarnPriceValue) / 1000
                
                totalWarpCost += warpCost
                totalWeftCost += weftCost
                
                let materialResult = MaterialCalculationResult(
                    material: material,
                    warpWeight: materialWarpWeight,
                    weftWeight: materialWeftWeight,
                    warpCost: warpCost,
                    weftCost: weftCost
                )
                perMaterialResults.append(materialResult)
            }
        } else {
            // Standard calculation or partial direct weight
            // Direction-specific totals only (no fallback to generic ratio)
            let totalWarpRatio = materials.map { Double($0.warpRatio ?? "0") ?? 0 }.reduce(0, +)
            let totalWeftRatio = materials.map { Double($0.weftRatio ?? "0") ?? 0 }.reduce(0, +)
            
            for material in materials {
                // Validate material
                let materialValidation = InputValidator.validateMaterial(
                    material,
                    useDirectWarpWeight: useDirectWarpWeight,
                    useDirectWeftWeight: useDirectWeftWeight
                )
                if case .failure(let message) = materialValidation {
                    return .failure(.materialValidationFailed(message))
                }
                
                guard let materialResult = calculateSingleMaterialCost(
                    material: material,
                    validatedValues: validatedValues,
                    constants: constants,
                    totalWarpRatio: totalWarpRatio,
                    totalWeftRatio: totalWeftRatio,
                    useDirectWarpWeight: useDirectWarpWeight,
                    directWarpWeight: directWarpWeight,
                    useDirectWeftWeight: useDirectWeftWeight,
                    directWeftWeight: directWeftWeight
                ) else {
                    return .failure(.materialCalculationFailed("材料\(material.name)计算失败。"))
                }
                
                totalWarpWeight += materialResult.warpWeight
                totalWeftWeight += materialResult.weftWeight
                totalWarpCost += materialResult.warpCost
                totalWeftCost += materialResult.weftCost
                perMaterialResults.append(materialResult)
            }
        }
        
        return .success(MaterialCalculationResults(
            totalWarpWeight: totalWarpWeight,
            totalWeftWeight: totalWeftWeight,
            totalWarpCost: totalWarpCost,
            totalWeftCost: totalWeftCost,
            perMaterialResults: perMaterialResults
        ))
    }
    
    private static func calculateSingleMaterialCost(
        material: Material,
        validatedValues: ValidatedValues,
        constants: CalculationConstants,
        totalWarpRatio: Double,
        totalWeftRatio: Double,
        useDirectWarpWeight: Bool = false,
        directWarpWeight: String = "",
        useDirectWeftWeight: Bool = false,
        directWeftWeight: String = ""
    ) -> MaterialCalculationResult? {
        
        // Extract material values
        let materialWarpRatio = Double(material.warpRatio ?? "0") ?? 0
        let materialWeftRatio = Double(material.weftRatio ?? "0") ?? 0
        let warpYarnValueNumber = Double(material.warpYarnValue) ?? 0
        let weftYarnValueNumber = Double(material.weftYarnValue) ?? 0
        let warpYarnPriceValue = Double(material.warpYarnPrice) ?? 0
        let weftYarnPriceValue = Double(material.weftYarnPrice) ?? 0
        
        // Calculate D values
        let warpDValue = calculateDValue(
            yarnValue: warpYarnValueNumber,
            yarnType: material.warpYarnTypeSelection,
            defaultDValue: constants.defaultDValue
        )
        let weftDValue = calculateDValue(
            yarnValue: weftYarnValueNumber,
            yarnType: material.weftYarnTypeSelection,
            defaultDValue: constants.defaultDValue
        )
        
        // Calculate ratio fractions
        let warpRatioFraction = materialWarpRatio / totalWarpRatio
        let weftRatioFraction = materialWeftRatio / totalWeftRatio
        
        // Warp calculations
        let warpWeight: Double
        if useDirectWarpWeight, let directWarpWeightValue = Double(directWarpWeight) {
            warpWeight = directWarpWeightValue * warpRatioFraction
        } else {
            let warpEnds = validatedValues.boxNumber * validatedValues.threading * validatedValues.actualFabricWidth
            warpWeight = (warpEnds * warpDValue * validatedValues.fabricShrinkage) / constants.warpDivider * warpRatioFraction
        }
        let warpCost = (warpWeight * warpYarnPriceValue) / 1000
        
        // Weft calculations
        let weftWeight: Double
        if useDirectWeftWeight, let directWeftWeightValue = Double(directWeftWeight) {
            weftWeight = directWeftWeightValue * weftRatioFraction
        } else {
            weftWeight = (weftDValue * validatedValues.actualFabricWidth * validatedValues.weftDensity) / constants.weftDivider * weftRatioFraction
        }
        let weftCost = (weftWeight * weftYarnPriceValue) / 1000
        
        return MaterialCalculationResult(
            material: material,
            warpWeight: warpWeight,
            weftWeight: weftWeight,
            warpCost: warpCost,
            weftCost: weftCost
        )
    }
    
    private static func calculateDValue(yarnValue: Double, yarnType: YarnType, defaultDValue: Double) -> Double {
        if yarnType == .dNumber {
            return yarnValue
        }
        // Avoid division by zero when using yarn count
        guard yarnValue > 0 else { return 0 }
        return defaultDValue / yarnValue
    }
    
    private static func updateCalculationResults(
        calculationResults: CalculationResults,
        materialResults: MaterialCalculationResults,
        validatedValues: ValidatedValues,
        constants: CalculationConstants
    ) {
        // Update material results
        calculationResults.perMaterialResults = materialResults.perMaterialResults
        calculationResults.warpWeight = materialResults.totalWarpWeight
        calculationResults.weftWeight = materialResults.totalWeftWeight
        calculationResults.warpCost = materialResults.totalWarpCost
        calculationResults.weftCost = materialResults.totalWeftCost
        
        // Update warping cost
        calculationResults.warpingCost = validatedValues.fixedCost
        
        // Calculate labor cost (safe guards for division by zero / invalid values)
        let denominator = validatedValues.weftDensity * 100
        let numerator = (validatedValues.machineSpeed * (validatedValues.efficiency / 100) * constants.minutesPerDay)
        let rawDailyProduct = denominator != 0 ? (numerator / denominator) : 0
        let dailyProduct = rawDailyProduct.isFinite && rawDailyProduct > 0 ? rawDailyProduct : 0
        calculationResults.dailyProduct = dailyProduct
        calculationResults.laborCost = dailyProduct > 0 ? (validatedValues.dailyLaborCost / dailyProduct) : 0
        
        // Calculate total cost
        calculationResults.totalCost = calculationResults.warpCost + calculationResults.weftCost + calculationResults.warpingCost + calculationResults.laborCost
    }
}

