//
//  CalculationHistory.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import Foundation
import CloudKit

class CalculationHistory: ObservableObject {
    @Published var records: [CalculationRecord] = []

    private let privateDatabase = CKContainer.default().privateCloudDatabase

    init() {
        fetchRecordsFromCloud()
    }

    func fetchRecordsFromCloud() {
        let query = CKQuery(recordType: "CalculationRecord", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        var fetchedRecords: [CalculationRecord] = []

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                if let calculationRecord = CalculationRecord(from: record) {
                    fetchedRecords.append(calculationRecord)
                }
            case .failure(let error):
                print("Error fetching record \(recordID): \(error)")
            }
        }

        operation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Sort and update records
                    self?.records = fetchedRecords.sorted { $0.date > $1.date }
                case .failure(let error):
                    // Handle query error
                    print("Error fetching records: \(error)")
                }
            }
        }

        privateDatabase.add(operation)
    }


    func addRecord(_ record: CalculationRecord, retryCount: Int = 3) {
        let ckRecord = record.toCKRecord()
        privateDatabase.save(ckRecord) { [weak self] (savedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    let ckError = error as? CKError
                    if let ckError = ckError {
                        switch ckError.code {
                        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
                            if retryCount > 0 {
                                let retryAfter = ckError.userInfo[CKErrorRetryAfterKey] as? TimeInterval ?? 3.0
                                DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) {
                                    self?.addRecord(record, retryCount: retryCount - 1)
                                }
                            } else {
                                print("Failed after retries. Error: \(error)")
                            }
                        case .quotaExceeded:
                            print("CloudKit quota exceeded. Error: \(error)")
                        default:
                            print("Error saving record: \(error)")
                        }
                    }
                } else {
                    self?.records.insert(record, at: 0)
                }
            }
        }
    }

    func updateRecord(_ record: CalculationRecord) {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] (fetchedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching record: \(error)")
                    return
                }
                
                if let fetchedRecord = fetchedRecord {
                    fetchedRecord["customerName"] = record.customerName as CKRecordValue
                    fetchedRecord["boxNumber"] = record.boxNumber as CKRecordValue
                    fetchedRecord["threading"] = record.threading as CKRecordValue
                    fetchedRecord["edgeFinishing"] = record.edgeFinishing as CKRecordValue
                    fetchedRecord["fabricWidth"] = record.fabricWidth as CKRecordValue
                    fetchedRecord["fabricShrinkage"] = record.fabricShrinkage as CKRecordValue
                    fetchedRecord["warpYarnPrice"] = record.warpYarnPrice as CKRecordValue
                    fetchedRecord["weftYarnPrice"] = record.weftYarnPrice as CKRecordValue
                    fetchedRecord["weftDensity"] = record.weftDensity as CKRecordValue
                    fetchedRecord["machineSpeed"] = record.machineSpeed as CKRecordValue
                    fetchedRecord["efficiency"] = record.efficiency as CKRecordValue
                    fetchedRecord["dailyLaborCost"] = record.dailyLaborCost as CKRecordValue
                    fetchedRecord["fixedCost"] = record.fixedCost as CKRecordValue
                    fetchedRecord["warpYarnValue"] = record.warpYarnValue as CKRecordValue
                    fetchedRecord["warpYarnTypeSelection"] = record.warpYarnTypeSelection.rawValue as CKRecordValue
                    fetchedRecord["weftYarnValue"] = record.weftYarnValue as CKRecordValue
                    fetchedRecord["weftYarnTypeSelection"] = record.weftYarnTypeSelection.rawValue as CKRecordValue
                    fetchedRecord["warpCost"] = record.warpCost as CKRecordValue
                    fetchedRecord["weftCost"] = record.weftCost as CKRecordValue
                    fetchedRecord["warpingCost"] = record.warpingCost as CKRecordValue
                    fetchedRecord["laborCost"] = record.laborCost as CKRecordValue
                    fetchedRecord["totalCost"] = record.totalCost as CKRecordValue
                    fetchedRecord["dailyProduct"] = record.dailyProduct as CKRecordValue
                    fetchedRecord["date"] = record.date as CKRecordValue

                    // Handle constants (you can store them as a dictionary or individual fields)
                    if let jsonData = try? JSONSerialization.data(withJSONObject: record.constants.toDictionary(), options: []) {
                        fetchedRecord["constants"] = jsonData as CKRecordValue
                    }

                    self?.privateDatabase.save(fetchedRecord) { (savedRecord, saveError) in
                        DispatchQueue.main.async {
                            if let saveError = saveError {
                                print("Error saving record: \(saveError)")
                            } else {
                                print("Record successfully updated.")
                            }
                        }
                    }
                }
            }
        }
    }


    func deleteRecord(_ record: CalculationRecord) {
        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        privateDatabase.delete(withRecordID: recordID) { [weak self] (deletedRecordID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting record: \(error)")
                } else {
                    if let index = self?.records.firstIndex(where: { $0.id == record.id }) {
                        self?.records.remove(at: index)
                    }
                }
            }
        }
    }
    
    public func saveHistory() {
        guard let firstRecord = self.records.first else {
            print("No records to save.")
            return
        }
        addRecord(firstRecord)
    }
    
}

