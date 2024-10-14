//
//  EditCalculationView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-01.
//


import SwiftUI

struct EditCalculationView: View {
    @EnvironmentObject var calculationHistory: CalculationHistory
    @Environment(\.presentationMode) var presentationMode

    @State private var record: CalculationRecord

    // State variables for inputs
    @State private var customerName: String
    @State private var boxNumber: String
    @State private var threading: String
    @State private var fabricWidth: String
    @State private var edgeFinishing: String
    @State private var fabricShrinkage: String
    @State private var warpYarnPrice: String
    @State private var weftYarnPrice: String
    @State private var weftDensity: String
    @State private var machineSpeed: String
    @State private var efficiency: String
    @State private var dailyLaborCost: String
    @State private var fixedCost: String
    @State private var warpYarnValue: String
    @State private var warpYarnTypeSelection: YarnType
    @State private var weftYarnValue: String
    @State private var weftYarnTypeSelection: YarnType
    @State private var constants: CalculationConstants

    // Calculation results
    @StateObject private var calculationResults = CalculationResults()

    // Alert message
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(record: CalculationRecord) {
        _record = State(initialValue: record)
        _customerName = State(initialValue: record.customerName)
        _boxNumber = State(initialValue: record.boxNumber)
        _threading = State(initialValue: record.threading)
        _fabricWidth = State(initialValue: record.fabricWidth)
        _edgeFinishing = State(initialValue: record.edgeFinishing)
        _fabricShrinkage = State(initialValue: record.fabricShrinkage)
        _warpYarnPrice = State(initialValue: record.warpYarnPrice)
        _weftYarnPrice = State(initialValue: record.weftYarnPrice)
        _weftDensity = State(initialValue: record.weftDensity)
        _machineSpeed = State(initialValue: record.machineSpeed)
        _efficiency = State(initialValue: record.efficiency)
        _dailyLaborCost = State(initialValue: record.dailyLaborCost)
        _fixedCost = State(initialValue: record.fixedCost)
        _warpYarnValue = State(initialValue: record.warpYarnValue)
        _warpYarnTypeSelection = State(initialValue: record.warpYarnTypeSelection)
        _weftYarnValue = State(initialValue: record.weftYarnValue)
        _weftYarnTypeSelection = State(initialValue: record.weftYarnTypeSelection)
        _constants = State(initialValue: record.constants)
    }

    var body: some View {
        Form {
            Section(header: Text("客户信息")) {
                SuffixTextField(label: "客户名称/ID", text: $customerName, suffix: "")
            }

            Section(header: Text("输入参数")) {
                SuffixTextField(label: "筘号", text: $boxNumber, suffix: "", keyboardType: .decimalPad)
                SuffixTextField(label: "穿入", text: $threading, suffix: "", keyboardType: .decimalPad)
                SuffixTextField(label: "门幅", text: $fabricWidth, suffix: "cm", keyboardType: .decimalPad)
                SuffixTextField(label: "加边", text: $edgeFinishing, suffix: "cm", keyboardType: .decimalPad)
                YarnInputField(yarnValue: $warpYarnValue, yarnTypeSelection: $warpYarnTypeSelection, label: "经纱")
                YarnInputField(yarnValue: $weftYarnValue, yarnTypeSelection: $weftYarnTypeSelection, label: "纬纱")
                SuffixTextField(label: "织缩", text: $fabricShrinkage, suffix: "", keyboardType: .decimalPad)
                SuffixTextField(label: "经纱纱价", text: $warpYarnPrice, suffix: "元/kg", keyboardType: .decimalPad)
                SuffixTextField(label: "纬纱纱价", text: $weftYarnPrice, suffix: "元/kg", keyboardType: .decimalPad)
                SuffixTextField(label: "下机纬密", text: $weftDensity, suffix: "根/cm", keyboardType: .decimalPad)
                SuffixTextField(label: "车速", text: $machineSpeed, suffix: "RPM", keyboardType: .decimalPad)
                SuffixTextField(label: "效率", text: $efficiency, suffix: "%", keyboardType: .decimalPad)
                SuffixTextField(label: "日工费", text: $dailyLaborCost, suffix: "元", keyboardType: .decimalPad)
                SuffixTextField(label: "牵经费用", text: $fixedCost, suffix: "元/米", keyboardType: .decimalPad)
            }

            Section {
                Button(action: {
                    updateCalculation()
                }) {
                    Text("更新计算")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("编辑计算")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("输入错误"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("确定")))
        }
    }

    func updateCalculation() {
        var alertMessage = ""
        let calculationSuccess = Calculator.calculate(
            boxNumber: boxNumber,
            threading: threading,
            fabricWidth: fabricWidth,
            edgeFinishing: edgeFinishing,
            fabricShrinkage: fabricShrinkage,
            warpYarnPrice: warpYarnPrice,
            weftYarnPrice: weftYarnPrice,
            weftDensity: weftDensity,
            machineSpeed: machineSpeed,
            efficiency: efficiency,
            dailyLaborCost: dailyLaborCost,
            fixedCost: fixedCost,
            warpYarnValue: warpYarnValue,
            warpYarnTypeSelection: warpYarnTypeSelection,
            weftYarnValue: weftYarnValue,
            weftYarnTypeSelection: weftYarnTypeSelection,
            constants: constants,
            calculationResults: calculationResults,
            alertMessage: &alertMessage
        )

        if calculationSuccess {
            // Update the record
            let updatedRecord = CalculationRecord(
                id: record.id,
                customerName: customerName,
                boxNumber: boxNumber,
                threading: threading,
                fabricWidth: fabricWidth,
                edgeFinishing: edgeFinishing,
                fabricShrinkage: fabricShrinkage,
                warpYarnPrice: warpYarnPrice,
                weftYarnPrice: weftYarnPrice,
                weftDensity: weftDensity,
                machineSpeed: machineSpeed,
                efficiency: efficiency,
                dailyLaborCost: dailyLaborCost,
                fixedCost: fixedCost,
                warpYarnValue: warpYarnValue,
                warpYarnTypeSelection: warpYarnTypeSelection,
                weftYarnValue: weftYarnValue,
                weftYarnTypeSelection: weftYarnTypeSelection,
                constants: constants,
                warpCost: calculationResults.warpCost,
                weftCost: calculationResults.weftCost,
                warpingCost: calculationResults.warpingCost,
                laborCost: calculationResults.laborCost,
                totalCost: calculationResults.totalCost,
                dailyProduct: calculationResults.dailyProduct,
                date: Date()
            )

            if let index = calculationHistory.records.firstIndex(where: { $0.id == record.id }) {
                calculationHistory.records[index] = updatedRecord
                calculationHistory.updateRecord(updatedRecord)
            }

            presentationMode.wrappedValue.dismiss()
        } else {
            self.alertMessage = alertMessage
            self.showAlert = true
        }
    }
}
