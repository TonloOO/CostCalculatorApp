//
//  CostCalculatorView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI
import UIKit
import NaturalLanguage
import CoreData


struct CostCalculatorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // User inputs
    @State private var customerName: String = ""
    @State private var useDirectWarpWeight: Bool = false
    @State private var directWarpWeight: String = ""
    @State private var useDirectWeftWeight: Bool = false
    @State private var directWeftWeight: String = ""
    @State private var boxNumber: String = ""
    @State private var threading: String = ""
    @State private var fabricWidth: String = ""
    @State private var edgeFinishing: String = ""
    @State private var fabricShrinkage: String = ""
    @State private var useSameYarnPrice: Bool = true
    @State private var yarnPrice: String = ""
    @State private var warpYarnPrice: String = ""
    @State private var weftYarnPrice: String = ""
    @State private var weftDensity: String = ""
    @State private var machineSpeed: String = ""
    @State private var efficiency: String = ""
    @State private var dailyLaborCost: String = ""
    @State private var fixedCost: String = ""

    
    @State private var warpYarnValue: String = ""
    @State private var warpYarnTypeSelection: YarnType = .dNumber
    @State private var weftYarnValue: String = ""
    @State private var weftYarnTypeSelection: YarnType = .dNumber
    

    @State private var materials: [Material] = [
        Material(name: "单材料", warpYarnValue: "", warpYarnTypeSelection: .dNumber, weftYarnValue: "", weftYarnTypeSelection: .dNumber, warpYarnPrice: "", weftYarnPrice: "", warpRatio: "1", weftRatio: "1", ratio: "1")
    ]

    init(prefillData: TextileRecognitionResult? = nil) {
        guard let data = prefillData, let mat = data.materials.first else { return }
        _customerName = State(initialValue: data.customerName ?? "")
        _boxNumber = State(initialValue: data.boxNumber ?? "")
        _threading = State(initialValue: data.threading ?? "")
        _fabricWidth = State(initialValue: data.fabricWidth ?? "")
        _edgeFinishing = State(initialValue: data.edgeFinishing ?? "")
        _fabricShrinkage = State(initialValue: data.fabricShrinkage ?? "")
        _weftDensity = State(initialValue: data.weftDensity ?? "")
        _machineSpeed = State(initialValue: data.machineSpeed ?? "")
        _efficiency = State(initialValue: data.efficiency ?? "")
        _dailyLaborCost = State(initialValue: data.dailyLaborCost ?? "")
        _fixedCost = State(initialValue: data.fixedCost ?? "")

        let warpType: YarnType = mat.warpYarnType == "支数" ? .yarnCount : .dNumber
        let weftType: YarnType = mat.weftYarnType == "支数" ? .yarnCount : .dNumber
        _materials = State(initialValue: [
            Material(
                name: mat.name ?? "单材料",
                warpYarnValue: mat.warpYarnValue ?? "",
                warpYarnTypeSelection: warpType,
                weftYarnValue: mat.weftYarnValue ?? "",
                weftYarnTypeSelection: weftType,
                warpYarnPrice: mat.warpYarnPrice ?? "",
                weftYarnPrice: mat.weftYarnPrice ?? "",
                warpRatio: "1", weftRatio: "1", ratio: "1"
            )
        ])
    }



    // Constants
    @State private var constants: CalculationConstants = CalculationConstants.defaultConstants

    // Calculation results
    @StateObject private var calculationResults = CalculationResults()

    // Active sheet management
    @State private var activeSheet: ActiveSheet?
    @State private var clipboardContentToImport: String = ""
    @State private var lastSavedRecord: CalculationRecord?
    
    @State private var activeAlert: AlertType?
    @State private var showWarpPicker = false
    @State private var showWeftPicker = false


    enum ActiveSheet: Identifiable {
        case results
        case constants
        case history

        var id: Int { hashValue }
    }
    
    enum AlertType: Identifiable {
        case inputError(message: String)
        case clipboardContentImport

        var id: Int {
            switch self {
            case .inputError:
                return 0
            case .clipboardContentImport:
                return 1
            }
        }
    }

    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            customNavHeader(
                title: "单材料纱价计算",
                backLabel: "费用计算",
                dismiss: dismiss,
                trailing: {
                    HStack(spacing: 14) {
                        Button(action: { activeSheet = .history }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.Colors.primaryText)
                        }
                        Button(action: { activeSheet = .constants }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.Colors.primaryText)
                        }
                    }
                }
            )
            .padding(.bottom, AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.groupedBackground)
            
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
                    
                    // STEP 2 - 纱线参数（集成直接输入开关）
                    StepCard(step: 2, title: "纱线参数", icon: "circle.grid.cross") {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            // 经纱组
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
                            
                            // 纬纱组
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
                    
                    // STEP 3 - 基础参数
                    if !useDirectWarpWeight || !useDirectWeftWeight {
                        StepCard(step: 3, title: "基础参数", icon: "square.grid.2x2") {
                            VStack(spacing: AppTheme.Spacing.small) {
                                if !useDirectWarpWeight {
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
                    StepCard(step: useDirectWarpWeight && useDirectWeftWeight ? 3 : 4, title: "生产参数", icon: "gearshape.2") {
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
            
            // 浮动计算按钮
            Button(action: {
                HapticFeedbackManager.shared.impact(style: .medium)
                calculateCosts()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "function")
                    Text("计算总费用")
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
        .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                checkClipboardForParameters()
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .inputError(let message):
                return Alert(
                    title: Text("输入错误"),
                    message: Text(message),
                    dismissButton: .default(Text("确定"))
                )
            case .clipboardContentImport:
                return Alert(
                    title: Text("检测到剪贴板内容"),
                    message: Text("是否要从剪贴板导入参数并填写？"),
                    primaryButton: .default(Text("导入"), action: {
                        parseClipboardContent(clipboardContentToImport)
                    }),
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .results:
                NavigationView {
                    if let record = lastSavedRecord {
                        CalculationDetailView(
                            record: record,
                            dismissAction: { activeSheet = nil }
                        )
                    }
                }
            case .constants:
                ConstantsSheet(
                    constants: $constants,
                    dismissAction: { activeSheet = nil }
                )
            case .history:
                NavigationView {
                    HistoryView()
                        .navigationBarItems(trailing: Button("关闭") {
                            activeSheet = nil
                        })
                }
            }
        }
    }

    
    let parameterSynonyms: [String: [String]] = [
        "筘号": ["筘号", "k号", "筘", "k"],
        "经纱纱价": ["经纱价", "经纱纱价", "经纱价格", "经价", "经纱"],
        "纬纱纱价": ["纬纱价", "纬纱纱价", "纬纱价格", "纬价", "纬纱"],
        "车速": ["车速", "速度"],
        "效率": ["效率"],
        "门幅": ["门幅", "幅宽"],
        "穿入": ["穿入", "穿综"],
        "织缩": ["织缩", "缩率"],
        "下机纬密": ["下机纬密", "纬密"],
        "日工费": ["日工费", "工费"],
        "牵经费用": ["牵经费用", "牵经费"],
        "经纱规格": ["经纱规格", "经纱支数", "经纱D数"],
        "经纱类型": ["经纱类型"],
        "纬纱规格": ["纬纱规格", "纬纱支数", "纬纱D数"],
        "纬纱类型": ["纬纱类型"],
        "客户名称": ["客户名称", "客户", "名称"],
    ]

    
    var parameterMappings: [String: (String) -> Void] {
        return [
            "客户名称": { self.customerName = $0 },
            "筘号": { self.boxNumber = $0 },
            "穿入": { self.threading = $0 },
            "门幅": { self.fabricWidth = $0 },
            "织缩": { self.fabricShrinkage = $0 },
            "经纱纱价": { self.warpYarnPrice = $0 },
            "纬纱纱价": { self.weftYarnPrice = $0 },
            "下机纬密": { self.weftDensity = $0 },
            "车速": { self.machineSpeed = $0 },
            "效率": { self.efficiency = $0 },
            "日工费": { self.dailyLaborCost = $0 },
            "牵经费用": { self.fixedCost = $0 },
            "经纱规格": { self.warpYarnValue = $0 },
            "经纱类型": { self.warpYarnTypeSelection = YarnType(rawValue: $0) ?? .dNumber },
            "纬纱规格": { self.weftYarnValue = $0 },
            "纬纱类型": { self.weftYarnTypeSelection = YarnType(rawValue: $0) ?? .dNumber },
        ]
    }
    
    func extractParameters(from text: String) -> [String: String] {
        var extractedParameters = [String: String]()

        // Remove spaces for easier processing
        let cleanedText = text.replacingOccurrences(of: " ", with: "")
        // Tokenize the text into possible key-value pairs
        let components = cleanedText.components(separatedBy: CharacterSet(charactersIn: ",;，；"))

        for component in components {
            for (parameterKey, synonyms) in parameterSynonyms {
                for synonym in synonyms {
                    if component.contains(synonym) {
                        if let value = extractValue(after: synonym, in: component) {
                            extractedParameters[parameterKey] = value
                            break
                        }
                    }
                }
            }
        }

        return extractedParameters
    }

    func extractValue(after keyword: String, in text: String) -> String? {
        // Find the range of the keyword
        if let keywordRange = text.range(of: keyword) {
            var valueStartIndex = keywordRange.upperBound

            // Possible separators
            let possibleSeparators = [":", "：", "=", "-"]
            if valueStartIndex < text.endIndex {
                let nextChar = text[valueStartIndex]
                if possibleSeparators.contains(String(nextChar)) {
                    valueStartIndex = text.index(after: valueStartIndex)
                }
            }

            // Extract the value until the next parameter or end of string
            let remainingText = text[valueStartIndex...]
            // Look for the next parameter synonym to avoid capturing too much
            var valueEndIndex = text.endIndex
            for (_, synonyms) in parameterSynonyms {
                for synonym in synonyms {
                    if let range = remainingText.range(of: synonym) {
                        if range.lowerBound != remainingText.startIndex {
                            valueEndIndex = text.index(valueStartIndex, offsetBy: range.lowerBound.utf16Offset(in: remainingText))
                            break
                        }
                    }
                }
            }

            let valueRange = valueStartIndex..<valueEndIndex
            let value = String(text[valueRange]).trimmingCharacters(in: CharacterSet(charactersIn: ":：=-"))
            return value
        }
        return nil
    }

    
    func checkClipboardForParameters() {
        if let clipboardString = UIPasteboard.general.string {
            if containsParameters(in: clipboardString) {
                // Show an alert to the user
                showClipboardImportAlert(content: clipboardString)
            }
        }
    }
    
    func containsParameters(in content: String) -> Bool {
        for (_, synonyms) in parameterSynonyms {
            for synonym in synonyms {
                if content.contains(synonym) {
                    return true
                }
            }
        }
        return false
    }

    
    func showClipboardImportAlert(content: String) {
        clipboardContentToImport = content
        activeAlert = .clipboardContentImport
    }
    
    func parseClipboardContent(_ content: String) {
        let extractedParameters = extractParameters(from: content)

        for (parameter, value) in extractedParameters {
            if let setter = parameterMappings[parameter] {
                setter(value)
            }
        }
    }


    
    // 计算cost
    func calculateCosts() {
        var alertMessage = ""
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
            // Save calculation record
            let newRecord = CalculationRecord(context: viewContext)
            newRecord.id = UUID()
            newRecord.customerName = customerName
            newRecord.boxNumber =  boxNumber
            newRecord.threading =  threading
            newRecord.fabricWidth = fabricWidth
            newRecord.edgeFinishing = edgeFinishing
            newRecord.fabricShrinkage = fabricShrinkage
//            newRecord.warpYarnPrice = warpYarnPrice
//            newRecord.weftYarnPrice = weftYarnPrice
            newRecord.weftDensity = weftDensity
            newRecord.machineSpeed = machineSpeed
            newRecord.efficiency = efficiency
            newRecord.dailyLaborCost = dailyLaborCost
            newRecord.fixedCost = fixedCost
            newRecord.useDirectWarpWeight = useDirectWarpWeight
            newRecord.directWarpWeight = directWarpWeight
            newRecord.useDirectWeftWeight = useDirectWeftWeight
            newRecord.directWeftWeight = directWeftWeight
//            newRecord.warpYarnValue = warpYarnValue
//            newRecord.warpYarnTypeSelection = warpYarnTypeSelection.rawValue
//            newRecord.weftYarnValue = weftYarnValue
//            newRecord.weftYarnTypeSelection = weftYarnTypeSelection.rawValue
            
            // constants
            newRecord.defaultDValue = constants.defaultDValue
            newRecord.minutesPerDay = constants.minutesPerDay
            newRecord.warpDivider = constants.warpDivider
            newRecord.weftDivider = constants.weftDivider
            
            newRecord.warpCost = calculationResults.warpCost
            newRecord.weftCost = calculationResults.weftCost
            newRecord.warpWeight = calculationResults.warpWeight
            newRecord.weftWeight = calculationResults.weftWeight
            newRecord.warpingCost = calculationResults.warpingCost
            newRecord.laborCost = calculationResults.laborCost
            newRecord.totalCost = calculationResults.totalCost
            newRecord.dailyProduct = calculationResults.dailyProduct
            newRecord.date = Date()
            
            do {
                let encoder = JSONEncoder()
                newRecord.materialsResult = try encoder.encode(calculationResults.perMaterialResults)
            } catch {
                alertMessage = "无法保存材料数据：\(error.localizedDescription)"
                self.activeAlert = .inputError(message: alertMessage)
            }
            
            do {
                try viewContext.save()
                lastSavedRecord = newRecord
                activeSheet = .results
            } catch {
                let nsError = error as NSError
                alertMessage = "数据保存失败：\(nsError.localizedDescription)"
                self.activeAlert = .inputError(message: alertMessage)
            }
        } else {
            self.activeAlert = .inputError(message: alertMessage)
        }
    }

}
