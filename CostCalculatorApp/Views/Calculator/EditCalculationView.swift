//
//  EditCalculationView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-01.
//

import SwiftUI
import CoreData

struct EditCalculationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var record: CalculationRecord
    
    @State private var materials: [Material]
    
    // State variables for inputs
    @State private var customerName: String
    @State private var boxNumber: String
    @State private var threading: String
    @State private var fabricWidth: String
    @State private var edgeFinishing: String
    @State private var fabricShrinkage: String
    @State private var weftDensity: String
    @State private var machineSpeed: String
    @State private var efficiency: String
    @State private var dailyLaborCost: String
    @State private var fixedCost: String
    @State private var useDirectWarpWeight: Bool
    @State private var directWarpWeight: String
    @State private var useDirectWeftWeight: Bool
    @State private var directWeftWeight: String
    
    // For single material yarn type selection
    @State private var showWarpPicker = false
    @State private var showWeftPicker = false
    
    @State private var defaultDValue: Double
    @State private var minutesPerDay: Double
    @State private var warpDivider: Double
    @State private var weftDivider: Double

    // Calculation results
    @StateObject private var calculationResults = CalculationResults()

    // Alert message
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Initializer to load record data
    init(record: CalculationRecord) {
        _record = State(initialValue: record)

        // Initialize state variables from the record
        _customerName = State(initialValue: record.customerName ?? "")
        _boxNumber = State(initialValue: record.boxNumber ?? "")
        _threading = State(initialValue: record.threading ?? "")
        _fabricWidth = State(initialValue: record.fabricWidth ?? "")
        _edgeFinishing = State(initialValue: record.edgeFinishing ?? "")
        _fabricShrinkage = State(initialValue: record.fabricShrinkage ?? "")
        _weftDensity = State(initialValue: record.weftDensity ?? "")
        _machineSpeed = State(initialValue: record.machineSpeed ?? "")
        _efficiency = State(initialValue: record.efficiency ?? "")
        _dailyLaborCost = State(initialValue: record.dailyLaborCost ?? "")
        _fixedCost = State(initialValue: record.fixedCost ?? "")
        _useDirectWarpWeight = State(initialValue: record.useDirectWarpWeight)
        _directWarpWeight = State(initialValue: record.directWarpWeight ?? "")
        _useDirectWeftWeight = State(initialValue: record.useDirectWeftWeight)
        _directWeftWeight = State(initialValue: record.directWeftWeight ?? "")

        // Constants
        _defaultDValue = State(initialValue: record.defaultDValue)
        _minutesPerDay = State(initialValue: record.minutesPerDay)
        _warpDivider = State(initialValue: record.warpDivider)
        _weftDivider = State(initialValue: record.weftDivider)

        // Decode materials
        let decoder = JSONDecoder()
        if let materialsData = record.materialsResult {
            do {
                let decodedResults = try decoder.decode([MaterialCalculationResult].self, from: materialsData)
                _materials = State(initialValue: decodedResults.map { $0.material })
            } catch {
                print("解析材料失败: \(error)")
                _materials = State(initialValue: [
                    Material(name: "材料1", warpYarnValue: "", warpYarnTypeSelection: .dNumber, weftYarnValue: "", weftYarnTypeSelection: .dNumber, warpYarnPrice: "", weftYarnPrice: "", warpRatio: "1", weftRatio: "1", ratio: "1")
                ])
            }
        } else {
            _materials = State(initialValue: [
                Material(name: "材料1", warpYarnValue: "", warpYarnTypeSelection: .dNumber, weftYarnValue: "", weftYarnTypeSelection: .dNumber, warpYarnPrice: "", weftYarnPrice: "", warpRatio: "1", weftRatio: "1", ratio: "1")
            ])
        }
    }

    var body: some View {
        Form {
            Section(header: Text("客户信息")) {
                SuffixTextField(label: "客户名称/单号", text: $customerName, suffix: "")
            }
            
            Section(header: Text("直接输入重量")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle("直接输入经纱重量", isOn: $useDirectWarpWeight)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    if useDirectWarpWeight {
                        SuffixTextField(label: "经纱重量", text: $directWarpWeight, suffix: "g/m", keyboardType: .decimalPad)
                    }
                    
                    HStack {
                        Toggle("直接输入纬纱重量", isOn: $useDirectWeftWeight)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    if useDirectWeftWeight {
                        SuffixTextField(label: "纬纱重量", text: $directWeftWeight, suffix: "g/m", keyboardType: .decimalPad)
                    }
                }
            }

            // Show single material input fields if only one material (single material mode)
            if materials.count == 1 {
                // Single material mode - show fields directly like in creation view
                EmptyView()
            } else {
                // Multi-material mode - show material list
                Section(header: HStack {
                    Text("材料列表")
                    Spacer()
                    Button(action: {
                        HapticFeedbackManager.shared.impact(style: .medium)
                        materials.append(Material(name: "材料" + String(materials.count + 1), warpYarnValue: "", warpYarnTypeSelection: .dNumber, weftYarnValue: "", weftYarnTypeSelection: .dNumber, warpYarnPrice: "", weftYarnPrice: "", warpRatio: "1", weftRatio: "1", ratio: "1"))
                    }) {
                        Image(systemName: "plus")
                    }
                }) {
                    ForEach($materials) { material in
                        MaterialRow(material: material, materialsBinding: $materials)
                    }
                    .onDelete(perform: deleteMaterials)
                }
            }
            
            Section(header: Text("输入参数")) {
                Group {
                    if !useDirectWarpWeight {
                        SuffixTextField(label: "筘号", text: $boxNumber, suffix: "", keyboardType: .decimalPad)
                        SuffixTextField(label: "穿入", text: $threading, suffix: "", keyboardType: .decimalPad)
                        SuffixTextField(label: "门幅", text: $fabricWidth, suffix: "cm", keyboardType: .decimalPad)
                        SuffixTextField(label: "加边", text: $edgeFinishing, suffix: "cm", keyboardType: .decimalPad)
                        SuffixTextField(label: "织缩", text: $fabricShrinkage, suffix: "", keyboardType: .decimalPad)
                    } else {
                        if !useDirectWeftWeight {
                            SuffixTextField(label: "门幅", text: $fabricWidth, suffix: "cm", keyboardType: .decimalPad)
                            SuffixTextField(label: "加边", text: $edgeFinishing, suffix: "cm", keyboardType: .decimalPad)
                        }
                    }
                    
                    // Add yarn fields for single material mode
                    if materials.count == 1 {
                        YarnInputField(yarnValue: $materials[0].warpYarnValue, yarnTypeSelection: $materials[0].warpYarnTypeSelection, showPicker: $showWarpPicker, label: "经纱")
                        YarnInputField(yarnValue: $materials[0].weftYarnValue, yarnTypeSelection: $materials[0].weftYarnTypeSelection, showPicker: $showWeftPicker, label: "纬纱")
                        SuffixTextField(label: "经纱纱价", text: $materials[0].warpYarnPrice, suffix: "元", keyboardType: .decimalPad)
                        SuffixTextField(label: "纬纱纱价", text: $materials[0].weftYarnPrice, suffix: "元", keyboardType: .decimalPad)
                    }
                    
                    if !useDirectWeftWeight {
                        SuffixTextField(label: "下机纬密", text: $weftDensity, suffix: "根/cm", keyboardType: .decimalPad)
                    }
                    
                    SuffixTextField(label: "车速", text: $machineSpeed, suffix: "RPM", keyboardType: .decimalPad)
                    SuffixTextField(label: "效率", text: $efficiency, suffix: "%", keyboardType: .decimalPad)
                    SuffixTextField(label: "日工费", text: $dailyLaborCost, suffix: "元", keyboardType: .decimalPad)
                    SuffixTextField(label: "牵经费用", text: $fixedCost, suffix: "元/米", keyboardType: .decimalPad)
                }
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
    
    private func deleteMaterials(at offsets: IndexSet) {
        // Don't allow deletion if it would leave no materials
        if materials.count > 1 {
            materials.remove(atOffsets: offsets)
        }
    }
    
    func updateCalculation() {
        var alertMessage = ""
        let constants: CalculationConstants = CalculationConstants.defaultConstants
        
        constants.defaultDValue = defaultDValue
        constants.minutesPerDay = minutesPerDay
        constants.warpDivider = warpDivider
        constants.weftDivider = weftDivider
        
        let calculationSuccess = Calculator.calculate(
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
            materials: materials,
            constants: constants,
            calculationResults: calculationResults,
            useDirectWarpWeight: useDirectWarpWeight,
            directWarpWeight: directWarpWeight,
            useDirectWeftWeight: useDirectWeftWeight,
            directWeftWeight: directWeftWeight,
            alertMessage: &alertMessage
        )

        if calculationSuccess {
            // Update the record
            record.customerName = customerName
            record.boxNumber = boxNumber
            record.threading = threading
            record.fabricWidth = fabricWidth
            record.edgeFinishing = edgeFinishing
            record.fabricShrinkage = fabricShrinkage

            record.weftDensity = weftDensity
            record.machineSpeed = machineSpeed
            record.efficiency = efficiency
            record.dailyLaborCost = dailyLaborCost
            record.fixedCost = fixedCost
            record.useDirectWarpWeight = useDirectWarpWeight
            record.directWarpWeight = directWarpWeight
            record.useDirectWeftWeight = useDirectWeftWeight
            record.directWeftWeight = directWeftWeight

            // constants
            record.defaultDValue = constants.defaultDValue
            record.minutesPerDay = constants.minutesPerDay
            record.warpDivider = constants.warpDivider
            record.weftDivider = constants.weftDivider
            
            record.warpCost = calculationResults.warpCost
            record.weftCost = calculationResults.weftCost
            record.warpWeight = calculationResults.warpWeight
            record.weftWeight = calculationResults.weftWeight
            record.warpingCost = calculationResults.warpingCost
            record.laborCost = calculationResults.laborCost
            record.totalCost = calculationResults.totalCost
            record.dailyProduct = calculationResults.dailyProduct
            record.date = Date()

            do {
                let encoder = JSONEncoder()
                record.materialsResult = try encoder.encode(calculationResults.perMaterialResults)
            } catch {
                alertMessage = "无法保存材料数据：\(error.localizedDescription)"
                showAlert = true
            }
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                alertMessage = "更新失败：\(nsError.localizedDescription)"
                showAlert = true
            }
        } else {
            self.alertMessage = alertMessage
            self.showAlert = true
        }
    }
}
