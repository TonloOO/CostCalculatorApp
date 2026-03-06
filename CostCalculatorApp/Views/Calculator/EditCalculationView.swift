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

    private var isSingleMaterial: Bool { materials.count == 1 }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // STEP 1 - 客户信息
                    StepCard(step: 1, title: "客户信息", icon: "person.circle") {
                        CompactInputField(config: InputFieldConfig(
                            label: "客户名称/单号",
                            text: $customerName,
                            suffix: "",
                            keyboardType: .default
                        ))
                    }
                    
                    if isSingleMaterial {
                        // 单材料 - 纱线参数（集成直接输入开关）
                        StepCard(step: 2, title: "纱线参数", icon: "circle.grid.cross") {
                            VStack(spacing: AppTheme.Spacing.medium) {
                                VStack(spacing: AppTheme.Spacing.small) {
                                    HStack {
                                        Text("经纱")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppTheme.Colors.primaryText)
                                        Spacer()
                                        Toggle("直接输入克重", isOn: $useDirectWarpWeight)
                                            .font(.system(size: 12))
                                            .toggleStyle(.switch)
                                            .controlSize(.mini)
                                            .fixedSize()
                                    }
                                    if useDirectWarpWeight {
                                        CompactInputRow(
                                            leftField: InputFieldConfig(label: "经纱重量", text: $directWarpWeight, suffix: "g/m"),
                                            rightField: InputFieldConfig(label: "经纱纱价", text: $materials[0].warpYarnPrice, suffix: "元")
                                        )
                                    } else {
                                        HStack(spacing: AppTheme.Spacing.small) {
                                            CompactYarnInputField(
                                                yarnValue: $materials[0].warpYarnValue,
                                                yarnTypeSelection: $materials[0].warpYarnTypeSelection,
                                                label: "经纱"
                                            )
                                            CompactInputField(config: InputFieldConfig(
                                                label: "经纱纱价",
                                                text: $materials[0].warpYarnPrice,
                                                suffix: "元"
                                            ))
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                VStack(spacing: AppTheme.Spacing.small) {
                                    HStack {
                                        Text("纬纱")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppTheme.Colors.primaryText)
                                        Spacer()
                                        Toggle("直接输入克重", isOn: $useDirectWeftWeight)
                                            .font(.system(size: 12))
                                            .toggleStyle(.switch)
                                            .controlSize(.mini)
                                            .fixedSize()
                                    }
                                    if useDirectWeftWeight {
                                        CompactInputRow(
                                            leftField: InputFieldConfig(label: "纬纱重量", text: $directWeftWeight, suffix: "g/m"),
                                            rightField: InputFieldConfig(label: "纬纱纱价", text: $materials[0].weftYarnPrice, suffix: "元")
                                        )
                                    } else {
                                        HStack(spacing: AppTheme.Spacing.small) {
                                            CompactYarnInputField(
                                                yarnValue: $materials[0].weftYarnValue,
                                                yarnTypeSelection: $materials[0].weftYarnTypeSelection,
                                                label: "纬纱"
                                            )
                                            CompactInputField(config: InputFieldConfig(
                                                label: "纬纱纱价",
                                                text: $materials[0].weftYarnPrice,
                                                suffix: "元"
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // 多材料 - 材料列表
                        StepCard(step: 2, title: "材料列表", icon: "square.stack.3d.up", headerAction: {
                            HapticFeedbackManager.shared.impact(style: .medium)
                            materials.append(Material(name: "材料" + String(materials.count + 1), warpYarnValue: "", warpYarnTypeSelection: .dNumber, weftYarnValue: "", weftYarnTypeSelection: .dNumber, warpYarnPrice: "", weftYarnPrice: "", warpRatio: "1", weftRatio: "1", ratio: "1"))
                        }) {
                            VStack(spacing: AppTheme.Spacing.small) {
                                ForEach(Array(materials.indices), id: \.self) { index in
                                    MaterialRow(
                                        material: $materials[index],
                                        materialsBinding: $materials,
                                        colorIndex: index,
                                        onDelete: materials.count > 1 ? {
                                            let i = index
                                            withAnimation { _ = materials.remove(at: i) }
                                        } : nil
                                    )
                                }
                                
                                if materials.count >= 2 {
                                    LiveMaterialRatioBar(materials: materials)
                                        .padding(.top, AppTheme.Spacing.xSmall)
                                }
                            }
                        }
                    }
                    
                    // STEP 3 - 基础参数
                    if !useDirectWarpWeight || !useDirectWeftWeight || !isSingleMaterial {
                        StepCard(step: 3, title: "基础参数", icon: "square.grid.2x2") {
                            VStack(spacing: AppTheme.Spacing.small) {
                                if !useDirectWarpWeight || !isSingleMaterial {
                                    CompactInputRow(
                                        leftField: InputFieldConfig(label: "筘号", text: $boxNumber),
                                        rightField: InputFieldConfig(label: "穿入", text: $threading)
                                    )
                                    CompactInputRow(
                                        leftField: InputFieldConfig(label: "门幅", text: $fabricWidth, suffix: "cm"),
                                        rightField: InputFieldConfig(label: "加边", text: $edgeFinishing, suffix: "cm")
                                    )
                                    CompactInputField(config: InputFieldConfig(
                                        label: "织缩",
                                        text: $fabricShrinkage
                                    ))
                                } else if !useDirectWeftWeight {
                                    CompactInputRow(
                                        leftField: InputFieldConfig(label: "门幅", text: $fabricWidth, suffix: "cm"),
                                        rightField: InputFieldConfig(label: "加边", text: $edgeFinishing, suffix: "cm")
                                    )
                                }
                            }
                        }
                    }
                    
                    // STEP 4 - 生产参数
                    StepCard(step: (useDirectWarpWeight && useDirectWeftWeight && isSingleMaterial) ? 3 : 4, title: "生产参数", icon: "gearshape.2") {
                        VStack(spacing: AppTheme.Spacing.small) {
                            CompactInputRow(
                                leftField: InputFieldConfig(label: "下机纬密", text: $weftDensity, suffix: "根/cm"),
                                rightField: InputFieldConfig(label: "车速", text: $machineSpeed, suffix: "RPM")
                            )
                            CompactInputRow(
                                leftField: InputFieldConfig(label: "效率", text: $efficiency, suffix: "%"),
                                rightField: InputFieldConfig(label: "日工费", text: $dailyLaborCost, suffix: "元")
                            )
                            CompactInputField(config: InputFieldConfig(
                                label: "牵经费用",
                                text: $fixedCost,
                                suffix: "元/米"
                            ))
                        }
                    }
                }
                .padding()
                .padding(.bottom, 70)
            }
            
            // 浮动更新按钮
            Button(action: {
                HapticFeedbackManager.shared.impact(style: .medium)
                updateCalculation()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("更新计算")
                }
                .font(AppTheme.Typography.buttonText)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.primaryGradient)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.bottom, AppTheme.Spacing.small)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.groupedBackground.opacity(0), AppTheme.Colors.groupedBackground],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 90)
                .allowsHitTesting(false)
            )
        }
        .background(AppTheme.Colors.groupedBackground)
        .navigationTitle("编辑计算")
        .navigationBarTitleDisplayMode(.inline)
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
