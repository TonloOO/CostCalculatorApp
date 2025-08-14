//
//  InputValidator.swift
//  CostCalculatorApp
//
//  Created by Claude on 2024-07-15.
//

import Foundation

struct InputValidator {
    
    // MARK: - Validation Results
    enum ValidationResult {
        case success(Double)
        case failure(String)
    }
    
    // MARK: - Common Validation Functions
    static func validatePositiveNumber(_ input: String, fieldName: String) -> ValidationResult {
        guard !input.isEmpty else {
            return .failure("请输入\(fieldName)。")
        }
        
        guard let value = Double(input), value >= 0 else {
            return .failure("请输入有效的\(fieldName)。")
        }
        
        return .success(value)
    }
    
    static func validateNonNegativeNumber(_ input: String, fieldName: String) -> ValidationResult {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        
        if trimmedInput.isEmpty {
            return .success(0)
        }
        
        guard let value = Double(trimmedInput), value >= 0 else {
            return .failure("请输入有效的\(fieldName)（大于等于零）。")
        }
        
        return .success(value)
    }
    
    static func validateRatio(_ input: String, materialName: String, ratioType: String) -> ValidationResult {
        return validateNonNegativeNumber(input, fieldName: "\(ratioType)\(materialName)比例")
    }
    
    static func validateYarnValue(_ input: String, materialName: String, yarnType: YarnType) -> ValidationResult {
        return validateNonNegativeNumber(input, fieldName: "\(materialName)\(yarnType.rawValue)")
    }
    
    static func validateYarnPrice(_ input: String, materialName: String, yarnDirection: String) -> ValidationResult {
        return validateNonNegativeNumber(input, fieldName: "\(materialName)\(yarnDirection)纱价")
    }
    
    // MARK: - Material Validation
    static func validateMaterialRatios(_ materials: [Material]) -> ValidationResult {
        // Use direction-specific ratios only; if empty or nil, treat as 0 (do not fallback to generic ratio)
        let totalWarpRatio = materials.map { Double($0.warpRatio ?? "0") ?? 0 }.reduce(0, +)
        let totalWeftRatio = materials.map { Double($0.weftRatio ?? "0") ?? 0 }.reduce(0, +)
        
        if totalWarpRatio == 0 || totalWeftRatio == 0 {
            return .failure("材料比例之和不能为零。")
        }
        
        return .success(totalWarpRatio + totalWeftRatio)
    }
    
    // MARK: - Batch Validation
    static func validateBasicInputs(
        boxNumber: String,
        threading: String,
        fabricWidth: String,
        edgeFinishing: String,
        fabricShrinkage: String,
        weftDensity: String,
        machineSpeed: String,
        efficiency: String,
        dailyLaborCost: String,
        fixedCost: String
    ) -> ValidationResult {
        
        let validations: [(String, String)] = [
            (boxNumber, "筘号"),
            (threading, "穿入值"),
            (fabricWidth, "门幅"),
            (edgeFinishing, "加边"),
            (fabricShrinkage, "织缩"),
            (weftDensity, "下机纬密"),
            (machineSpeed, "车速"),
            (efficiency, "效率"),
            (dailyLaborCost, "日工费"),
            (fixedCost, "牵经费用")
        ]
        
        for (value, fieldName) in validations {
            let result = validatePositiveNumber(value, fieldName: fieldName)
            if case .failure(let message) = result {
                return .failure(message)
            }
        }
        
        return .success(0)
    }
    
    static func validateBasicInputsWithWeightSwitches(
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
        useDirectWarpWeight: Bool,
        directWarpWeight: String,
        useDirectWeftWeight: Bool,
        directWeftWeight: String
    ) -> ValidationResult {
        
        var validations: [(String, String)] = []
        
        // Add common validations
        validations.append((machineSpeed, "车速"))
        validations.append((efficiency, "效率"))
        validations.append((dailyLaborCost, "日工费"))
        validations.append((fixedCost, "牵经费用"))
        
        // Add warp-related validations if not using direct weight
        if !useDirectWarpWeight {
            validations.append((boxNumber, "筘号"))
            validations.append((threading, "穿入值"))
            validations.append((fabricWidth, "门幅"))
            validations.append((edgeFinishing, "加边"))
            validations.append((fabricShrinkage, "织缩"))
        } else {
            // Validate direct warp weight
            let warpWeightResult = validatePositiveNumber(directWarpWeight, fieldName: "经纱重量")
            if case .failure(let message) = warpWeightResult {
                return .failure(message)
            }
            
            // Still need fabric width if not using direct weft weight
            if !useDirectWeftWeight {
                validations.append((fabricWidth, "门幅"))
                validations.append((edgeFinishing, "加边"))
            }
        }
        
        // Weft density is always required (daily product depends on it), even when using direct weft weight
        validations.append((weftDensity, "下机纬密"))
        if useDirectWeftWeight {
            // Validate direct weft weight additionally
            let weftWeightResult = validatePositiveNumber(directWeftWeight, fieldName: "纬纱重量")
            if case .failure(let message) = weftWeightResult {
                return .failure(message)
            }
        }
        
        for (value, fieldName) in validations {
            let result = validatePositiveNumber(value, fieldName: fieldName)
            if case .failure(let message) = result {
                return .failure(message)
            }
        }
        
        return .success(0)
    }
    
    static func validateMaterial(
        _ material: Material,
        useDirectWarpWeight: Bool = false,
        useDirectWeftWeight: Bool = false
    ) -> ValidationResult {
        // Validate warp ratio
        let warpRatioResult = validateRatio(
            material.warpRatio ?? "0",
            materialName: material.name,
            ratioType: "经纱"
        )
        if case .failure(let message) = warpRatioResult {
            return .failure(message)
        }
        
        // Validate weft ratio
        let weftRatioResult = validateRatio(
            material.weftRatio ?? "0",
            materialName: material.name,
            ratioType: "纬纱"
        )
        if case .failure(let message) = weftRatioResult {
            return .failure(message)
        }
        
        // Validate warp yarn values only if not using direct warp weight
        if !useDirectWarpWeight {
            let warpYarnResult = validateYarnValue(
                material.warpYarnValue,
                materialName: material.name,
                yarnType: material.warpYarnTypeSelection
            )
            if case .failure(let message) = warpYarnResult {
                return .failure(message)
            }
            // When using yarn count, value must be strictly greater than 0 to avoid division by zero
            if material.warpYarnTypeSelection == .yarnCount {
                guard let value = Double(material.warpYarnValue), value > 0 else {
                    return .failure("请输入有效的\(material.name)支数（大于零）。")
                }
            }
        }
        
        // Validate weft yarn values only if not using direct weft weight
        if !useDirectWeftWeight {
            let weftYarnResult = validateYarnValue(
                material.weftYarnValue,
                materialName: material.name,
                yarnType: material.weftYarnTypeSelection
            )
            if case .failure(let message) = weftYarnResult {
                return .failure(message)
            }
            // When using yarn count, value must be strictly greater than 0 to avoid division by zero
            if material.weftYarnTypeSelection == .yarnCount {
                guard let value = Double(material.weftYarnValue), value > 0 else {
                    return .failure("请输入有效的\(material.name)支数（大于零）。")
                }
            }
        }
        
        // Validate yarn prices (always required for cost calculation)
        let warpPriceResult = validateYarnPrice(
            material.warpYarnPrice,
            materialName: material.name,
            yarnDirection: "经纱"
        )
        if case .failure(let message) = warpPriceResult {
            return .failure(message)
        }
        
        let weftPriceResult = validateYarnPrice(
            material.weftYarnPrice,
            materialName: material.name,
            yarnDirection: "纬纱"
        )
        if case .failure(let message) = weftPriceResult {
            return .failure(message)
        }
        
        return .success(0)
    }
}