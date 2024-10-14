//
//  CalculationRecord.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation
import CloudKit

struct CalculationRecord: Identifiable, Codable {
    let id: UUID
    // New property for customer management
    let customerName: String
    // Input parameters
    let boxNumber: String
    let threading: String
    let fabricWidth: String
    let edgeFinishing: String
    let fabricShrinkage: String
    let warpYarnPrice: String
    let weftYarnPrice: String
    let weftDensity: String
    let machineSpeed: String
    let efficiency: String
    let dailyLaborCost: String
    let fixedCost: String
    let warpYarnValue: String
    let warpYarnTypeSelection: YarnType
    let weftYarnValue: String
    let weftYarnTypeSelection: YarnType
    // Constants
    let constants: CalculationConstants
    // Results
    let warpCost: Double
    let weftCost: Double
    let warpingCost: Double
    let laborCost: Double
    let totalCost: Double
    let dailyProduct: Double
    // Date
    let date: Date

    init(id: UUID = UUID(),
         customerName: String,
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
         warpCost: Double,
         weftCost: Double,
         warpingCost: Double,
         laborCost: Double,
         totalCost: Double,
         dailyProduct: Double,
         date: Date) {
        self.id = id
        self.customerName = customerName
        self.boxNumber = boxNumber
        self.threading = threading
        self.fabricWidth = fabricWidth
        self.edgeFinishing = edgeFinishing
        self.fabricShrinkage = fabricShrinkage
        self.warpYarnPrice = warpYarnPrice
        self.weftYarnPrice = weftYarnPrice
        self.weftDensity = weftDensity
        self.machineSpeed = machineSpeed
        self.efficiency = efficiency
        self.dailyLaborCost = dailyLaborCost
        self.fixedCost = fixedCost
        self.warpYarnValue = warpYarnValue
        self.warpYarnTypeSelection = warpYarnTypeSelection
        self.weftYarnValue = weftYarnValue
        self.weftYarnTypeSelection = weftYarnTypeSelection
        self.constants = constants
        self.warpCost = warpCost
        self.weftCost = weftCost
        self.warpingCost = warpingCost
        self.laborCost = laborCost
        self.totalCost = totalCost
        self.dailyProduct = dailyProduct
        self.date = date
    }
}


// Extension to convert to CKRecord
extension CalculationRecord {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "CalculationRecord", recordID: CKRecord.ID(recordName: id.uuidString))
        record["customerName"] = customerName as CKRecordValue
        record["boxNumber"] = boxNumber as CKRecordValue
        record["threading"] = threading as CKRecordValue
        record["edgeFinishing"] = edgeFinishing as CKRecordValue
        record["fabricWidth"] = fabricWidth as CKRecordValue
        record["fabricShrinkage"] = fabricShrinkage as CKRecordValue
        record["warpYarnPrice"] = warpYarnPrice as CKRecordValue
        record["weftYarnPrice"] = weftYarnPrice as CKRecordValue
        record["weftDensity"] = weftDensity as CKRecordValue
        record["machineSpeed"] = machineSpeed as CKRecordValue
        record["efficiency"] = efficiency as CKRecordValue
        record["dailyLaborCost"] = dailyLaborCost as CKRecordValue
        record["fixedCost"] = fixedCost as CKRecordValue
        record["warpYarnValue"] = warpYarnValue as CKRecordValue
        record["warpYarnTypeSelection"] = warpYarnTypeSelection.rawValue as CKRecordValue
        record["weftYarnValue"] = weftYarnValue as CKRecordValue
        record["weftYarnTypeSelection"] = weftYarnTypeSelection.rawValue as CKRecordValue
        record["warpCost"] = warpCost as CKRecordValue
        record["weftCost"] = weftCost as CKRecordValue
        record["warpingCost"] = warpingCost as CKRecordValue
        record["laborCost"] = laborCost as CKRecordValue
        record["totalCost"] = totalCost as CKRecordValue
        record["dailyProduct"] = dailyProduct as CKRecordValue
        record["date"] = date as CKRecordValue

        // Handle constants (you can store them as a dictionary or individual fields)
        if let jsonData = try? JSONSerialization.data(withJSONObject: constants.toDictionary(), options: []) {
            record["constants"] = jsonData as CKRecordValue
        }


        return record
    }

    init?(from record: CKRecord) {
        guard
            let customerName = record["customerName"] as? String,
            let boxNumber = record["boxNumber"] as? String,
            let threading = record["threading"] as? String,
            let edgeFinishing = record["edgeFinishing"] as? String,
            let fabricWidth = record["fabricWidth"] as? String,
            let fabricShrinkage = record["fabricShrinkage"] as? String,
            let warpYarnPrice = record["warpYarnPrice"] as? String,
            let weftYarnPrice = record["weftYarnPrice"] as? String,
            let weftDensity = record["weftDensity"] as? String,
            let machineSpeed = record["machineSpeed"] as? String,
            let efficiency = record["efficiency"] as? String,
            let dailyLaborCost = record["dailyLaborCost"] as? String,
            let fixedCost = record["fixedCost"] as? String,
            let warpYarnValue = record["warpYarnValue"] as? String,
            let warpYarnTypeRaw = record["warpYarnTypeSelection"] as? String,
            let warpYarnTypeSelection = YarnType(rawValue: warpYarnTypeRaw),
            let weftYarnValue = record["weftYarnValue"] as? String,
            let weftYarnTypeRaw = record["weftYarnTypeSelection"] as? String,
            let weftYarnTypeSelection = YarnType(rawValue: weftYarnTypeRaw),
            let warpCost = record["warpCost"] as? Double,
            let weftCost = record["weftCost"] as? Double,
            let warpingCost = record["warpingCost"] as? Double,
            let laborCost = record["laborCost"] as? Double,
            let totalCost = record["totalCost"] as? Double,
            let dailyProduct = record["dailyProduct"] as? Double,
            let date = record["date"] as? Date,
            let constantsData = record["constants"] as? Data,
            let constantsDict = try? JSONSerialization.jsonObject(with: constantsData, options: []) as? [String: Double],
            let constants = CalculationConstants(from: constantsDict)
        else {
            return nil
        }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.customerName = customerName
        self.boxNumber = boxNumber
        self.threading = threading
        self.edgeFinishing = edgeFinishing
        self.fabricWidth = fabricWidth
        self.fabricShrinkage = fabricShrinkage
        self.warpYarnPrice = warpYarnPrice
        self.weftYarnPrice = weftYarnPrice
        self.weftDensity = weftDensity
        self.machineSpeed = machineSpeed
        self.efficiency = efficiency
        self.dailyLaborCost = dailyLaborCost
        self.fixedCost = fixedCost
        self.warpYarnValue = warpYarnValue
        self.warpYarnTypeSelection = warpYarnTypeSelection
        self.weftYarnValue = weftYarnValue
        self.weftYarnTypeSelection = weftYarnTypeSelection
        self.warpCost = warpCost
        self.weftCost = weftCost
        self.warpingCost = warpingCost
        self.laborCost = laborCost
        self.totalCost = totalCost
        self.dailyProduct = dailyProduct
        self.date = date
        self.constants = constants
    }
}
