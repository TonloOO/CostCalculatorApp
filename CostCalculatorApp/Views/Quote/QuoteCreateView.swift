//
//  QuoteCreateView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-10.
//

import Combine
import SwiftUI

// MARK: - Row Data

struct MaterialRowData: Identifiable {
    let id = UUID()
    var usage: String = "经纱"
    var materialName: String = ""
    var materialNo: String = ""
    var denierNum: String = ""
    var patternPerQty: String = ""
    var perCent: String = ""
    var unitPrice: String = ""
    var yarnPrice: String = ""
    var providerName: String = ""
    var providerNo: String = ""
    var yarnCount: String = ""
    var remark: String = ""
}

struct FinishRowData: Identifiable {
    let id = UUID()
    var finishMode: String = ""
    var count: String = ""
    var price: String = ""
    var amount: String = ""
}

// MARK: - Sheet Type

enum QuoteFormSheet: Identifiable {
    case customer, material, salesperson, balanceType, sizingProvider
    case supplier(UUID)
    case finishMode(UUID)

    var id: String {
        switch self {
        case .customer: return "customer"
        case .material: return "material"
        case .salesperson: return "salesperson"
        case .balanceType: return "balanceType"
        case .sizingProvider: return "sizingProvider"
        case .supplier(let uid): return "supplier-\(uid)"
        case .finishMode(let uid): return "finishMode-\(uid)"
        }
    }
}

enum QuoteFormMode {
    case create
    case edit(QuoteDetail)
    case reference(QuoteDetail)

    var navigationTitle: String {
        switch self {
        case .create:
            return "新建报价单"
        case .edit:
            return "编辑报价单"
        case .reference:
            return "引用报价单"
        }
    }

    var successMessagePrefix: String {
        switch self {
        case .create:
            return "创建"
        case .edit:
            return "更新"
        case .reference:
            return "创建"
        }
    }

    var quoteNo: String? {
        switch self {
        case .create:
            return nil
        case .edit(let detail):
            return detail.quoteNo
        case .reference:
            return nil
        }
    }
}

// MARK: - Main View

struct QuoteCreateView: View {
    @StateObject private var vm: QuoteCreateViewModel
    @Environment(\.dismiss) private var dismiss
    private let onCompleted: (() -> Void)?

    init(mode: QuoteFormMode = .create, onCompleted: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: QuoteCreateViewModel(mode: mode))
        self.onCompleted = onCompleted
    }

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoadingInitial {
                    ProgressView("加载基础数据...")
                } else {
                    formContent
                }
            }
            .navigationTitle(vm.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isSubmitting {
                        ProgressView()
                    } else {
                        Button("保存") { Task { await vm.submit() } }
                            .disabled(!vm.isValid)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .interactiveDismissDisabled(vm.hasChanges)
        .task { await vm.loadInitialData() }
        .sheet(item: $vm.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .alert("提示", isPresented: $vm.showAlert) {
            Button("确定") {
                if vm.createdQuoteNo != nil {
                    onCompleted?()
                    dismiss()
                }
            }
        } message: {
            Text(vm.alertMessage)
        }
        .alert("更换物料", isPresented: $vm.showMaterialChangeConfirm) {
            Button("取消", role: .cancel) {
                vm.pendingMaterial = nil
            }
            Button("确认更换", role: .destructive) {
                if let mat = vm.pendingMaterial {
                    vm.confirmMaterialChange(mat)
                }
            }
        } message: {
            Text("更换物料将重新加载原料配方，当前已填写的原料信息将被覆盖，是否继续？")
        }
    }

    // MARK: - Form

    private var formContent: some View {
        Form {
            basicInfoSection
            materialSection
            materialsDetailSection
            pricingSection
            specsSection
            productionSection
            finishDetailSection
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        Section("基本信息") {
            pickerRow("客户", value: vm.customerName.isEmpty ? nil : vm.customerName, required: true) {
                vm.activeSheet = .customer
            }

            TextField("联系人", text: $vm.linkMan)

            pickerRow("业务员", value: vm.selectedSalesperson?.salesName) {
                vm.activeSheet = .salesperson
            }

            Picker("订单类型", selection: $vm.orderType) {
                Text("散单").tag("散单")
                Text("样单").tag("样单")
                Text("翻单").tag("翻单")
            }
            .pickerStyle(.menu)

            pickerRow("结算方式", value: vm.selectedBalanceType?.name) {
                vm.activeSheet = .balanceType
            }

            if !vm.sourceTypes.isEmpty {
                Picker("来源", selection: $vm.source) {
                    Text("—").tag("")
                    ForEach(vm.sourceTypes) { item in
                        Text(item.name).tag(item.name)
                    }
                }
                .pickerStyle(.menu)
            }

            DatePicker("交期", selection: $vm.deliveryDate, displayedComponents: .date)
            numField("订单数量", text: $vm.orderQty)
            TextField("备注", text: $vm.remark)
        }
    }

    // MARK: - Material

    private var materialSection: some View {
        Section {
            pickerRow("选择物料", value: vm.materialDisplayLabel) {
                vm.activeSheet = .material
            }

            if !vm.materialNo.isEmpty {
                infoRow("物料编号", vm.materialNo)
                infoRow("品名", vm.materialName)
            }
        } header: {
            Text("物料信息")
        } footer: {
            if vm.isLoadingBOM {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("正在加载原料配方…")
                }
                .font(.caption)
            } else if vm.materialGuid != nil && !vm.materialRows.isEmpty {
                Text("原料配方已自动填充，请确认单价、供应商和日产量")
            }
        }
    }

    // MARK: - Materials Detail (moved up, right after material selection)

    private var materialsDetailSection: some View {
        Section {
            if vm.materialRows.isEmpty && vm.materialGuid == nil {
                Text("请先选择物料，原料配方将自动填充")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach($vm.materialRows) { $row in
                    materialRowView(row: $row)
                }
                .onDelete { vm.materialRows.remove(atOffsets: $0) }
            }

            Button {
                vm.materialRows.append(MaterialRowData())
            } label: {
                Label("添加原料", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("原料明细")
                Spacer()
                if !vm.materialRows.isEmpty {
                    Text("\(vm.materialRows.count) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func materialRowView(row: Binding<MaterialRowData>) -> some View {
        let isExpanded = vm.expandedMaterialRows.contains(row.wrappedValue.id)

        VStack(alignment: .leading, spacing: 12) {
            // Header: usage tag + name + price summary
            HStack(spacing: 8) {
                Text(row.wrappedValue.usage)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(row.wrappedValue.usage == "经纱" ? AppTheme.Colors.primary : AppTheme.Colors.accent)
                    )

                Text(row.wrappedValue.materialName.isEmpty ? "未命名" : row.wrappedValue.materialName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                if !row.wrappedValue.materialNo.isEmpty {
                    Text(row.wrappedValue.materialNo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)

            Divider()

            // Price fields - always visible, prominent
            HStack(spacing: 12) {
                priceField("原料单价", text: row.unitPrice, color: AppTheme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                priceField("加工单价", text: row.yarnPrice, color: AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let cost = vm.perRowCostMap[row.wrappedValue.id] {
                HStack(spacing: 4) {
                    Image(systemName: "function")
                        .font(.caption2)
                    Text("原料成本")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "¥%.4f /米", cost))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.primary.opacity(0.08))
                )
            }

            HStack(alignment: .top, spacing: 12) {
                supplierActionCard(row: row)
                    .layoutPriority(1)
                detailToggleCard(rowId: row.wrappedValue.id, isExpanded: isExpanded)
                    .frame(width: 128)
            }

            if isExpanded {
                VStack(spacing: 6) {
                    Picker("用途", selection: row.usage) {
                        Text("经纱").tag("经纱")
                        Text("纬纱").tag("纬纱")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    TextField("原料名称", text: row.materialName)
                    TextField("原料编号", text: row.materialNo)
                    numField("D数", text: row.denierNum)
                    numField("根数", text: row.patternPerQty)
                    numField("占比%", text: row.perCent)
                    TextField("纱支", text: row.yarnCount)
                    TextField("备注", text: row.remark)
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemFill).opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 8)
    }

    private func priceField(_ label: String, text: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                Text("¥")
                    .font(.subheadline)
                    .foregroundColor(color)
                TextField("0.00", text: text)
                    .keyboardType(.decimalPad)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(UIColor.tertiarySystemFill))
            .cornerRadius(6)
        }
    }

    private func supplierActionCard(row: Binding<MaterialRowData>) -> some View {
        Button {
            vm.activeSheet = .supplier(row.wrappedValue.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("供应商")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text(row.wrappedValue.providerName.isEmpty ? "请选择" : row.wrappedValue.providerName)
                        .font(.subheadline)
                        .foregroundColor(row.wrappedValue.providerName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private func detailToggleCard(rowId: UUID, isExpanded: Bool) -> some View {
        Button {
            toggleMaterialExpansion(rowId)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("更多参数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text(isExpanded ? "收起" : "展开")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.primary)
                    Spacer(minLength: 4)
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "slider.horizontal.3")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private func toggleMaterialExpansion(_ rowId: UUID) {
        if vm.expandedMaterialRows.contains(rowId) {
            vm.expandedMaterialRows.remove(rowId)
        } else {
            vm.expandedMaterialRows.insert(rowId)
        }
    }

    // MARK: - Pricing (moved up, right after materials)

    private var pricingSection: some View {
        Section("价格信息") {
            numField("报价单价", text: $vm.quotePrice)
            infoRow("原料成本", vm.materialCostDisplay.isEmpty ? "自动计算" : vm.materialCostDisplay)
            infoRow("成本单价", vm.costPrice.isEmpty ? "自动计算" : vm.costPrice)
            infoRow("利润率%", vm.profitRate.isEmpty ? "自动计算" : vm.profitRate)
            numField("浆纱单价", text: $vm.sizingPrice)
            numField("磨毛单价", text: $vm.sandingPrice)
            infoRow("标准工费", vm.stdWeavePrice.isEmpty ? "自动计算" : vm.stdWeavePrice)
            numField("小样费用", text: $vm.sampleCost)
        }
    }

    // MARK: - Specs (collapsible)

    private var specsSection: some View {
        CollapsibleSection(
            title: "规格参数",
            isExpanded: $vm.isSpecsExpanded,
            badge: vm.specsFilledCount
        ) {
            numField("成品门幅(存档)", text: $vm.width)
            numField("筘号", text: $vm.reedId)
            numField("筘幅", text: $vm.fastenerRange)
            infoRow("筘入", vm.reedTypeDisplay)
            numField("废边长度(cm)", text: $vm.sideLength)
            numField("经缩%", text: $vm.warpWastagePercent)
            numField("总经根数", text: $vm.beamTotalEnd)
            numField("经密", text: $vm.warpDensity)
            numField("纬密", text: $vm.weftDensity)
            Text("成本计算只使用筘号、筘入、筘幅；成品门幅仅随报价单保存，不参与成本计算。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Production (collapsible)

    private var productionSection: some View {
        CollapsibleSection(
            title: "生产参数",
            isExpanded: $vm.isProductionExpanded,
            badge: vm.productionFilledCount
        ) {
            numField("车速", text: $vm.weaveSpeed)
            numField("综合效率%", text: $vm.weaveEff)
            numField("日产量", text: $vm.weaveDayOutput)
            numField("日机台成本", text: $vm.weaveDayCost)

            pickerRow("浆纱供应商", value: vm.sizingProviderName.isEmpty ? nil : vm.sizingProviderName) {
                vm.activeSheet = .sizingProvider
            }

            infoRow("日工费", vm.weaveDaySaleCost.isEmpty ? "自动计算" : vm.weaveDaySaleCost)
        }
    }

    // MARK: - Finish Detail (collapsible)

    private var finishDetailSection: some View {
        CollapsibleSection(
            title: "后整理明细",
            isExpanded: $vm.isFinishExpanded,
            badge: vm.finishRows.isEmpty ? 0 : vm.finishRows.count
        ) {
            ForEach($vm.finishRows) { $row in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        vm.activeSheet = .finishMode($row.wrappedValue.id)
                    } label: {
                        HStack {
                            Text("方式")
                            Spacer()
                            Text($row.wrappedValue.finishMode.isEmpty ? "请选择" : $row.wrappedValue.finishMode)
                                .foregroundColor($row.wrappedValue.finishMode.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.primary)

                    HStack(spacing: 12) {
                        numField("次数", text: $row.count)
                        numField("单价", text: $row.price)
                        numField("金额", text: $row.amount)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { vm.finishRows.remove(atOffsets: $0) }

            Button {
                vm.finishRows.append(FinishRowData())
            } label: {
                Label("添加后整理", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(for sheet: QuoteFormSheet) -> some View {
        switch sheet {
        case .customer:
            RefSearchSheet(
                title: "选择客户",
                items: vm.customerResults,
                isSearching: vm.isSearchingCustomers,
                display: { $0.name },
                subtitle: { [$0.code, $0.abbName].compactMap { $0 }.joined(separator: " · ") },
                onSearch: { vm.searchCustomers(keyword: $0) },
                onSelect: { vm.applyCustomer($0) }
            )
        case .material:
            RefSearchSheet(
                title: "选择物料",
                items: vm.materialResults,
                isSearching: vm.isSearchingMaterials,
                display: { $0.displayLabel },
                subtitle: {
                    [
                        $0.component,
                        $0.fastenerRange.map { "筘幅\($0)" },
                        $0.width.map { "成品门幅\($0)" }
                    ]
                    .compactMap { $0 }
                    .joined(separator: " · ")
                },
                onSearch: { vm.searchMaterials(keyword: $0) },
                onSelect: { vm.applyMaterial($0) }
            )
        case .salesperson:
            RefSearchSheet(
                title: "选择业务员",
                items: vm.filteredSalespeople,
                isSearching: false,
                display: { $0.salesName },
                subtitle: { $0.groupName },
                onSearch: { vm.salespersonFilter = $0 },
                onSelect: { vm.applySalesperson($0) }
            )
        case .balanceType:
            RefSearchSheet(
                title: "结算方式",
                items: vm.filteredBalanceTypes,
                isSearching: false,
                display: { $0.name },
                onSearch: { vm.balanceTypeFilter = $0 },
                onSelect: { vm.selectedBalanceType = $0; vm.activeSheet = nil }
            )
        case .sizingProvider:
            RefSearchSheet(
                title: "浆纱供应商",
                items: vm.sizingProviderResults,
                isSearching: vm.isSearchingSizingProviders,
                display: { $0.name },
                subtitle: { $0.code },
                onSearch: { vm.searchSizingProviders(keyword: $0) },
                onSelect: { vm.applySizingProvider($0) }
            )
        case .supplier(let rowId):
            RefSearchSheet(
                title: "选择供应商",
                items: vm.supplierResults,
                isSearching: vm.isSearchingSuppliers,
                display: { $0.name },
                subtitle: { $0.code },
                onSearch: { vm.searchSuppliers(keyword: $0) },
                onSelect: { vm.applySupplier($0, toRow: rowId) }
            )
        case .finishMode(let rowId):
            RefSearchSheet(
                title: "后整理方式",
                items: vm.filteredFinishModes,
                isSearching: false,
                display: { $0.name },
                onSearch: { vm.finishModeFilter = $0 },
                onSelect: { vm.applyFinishMode($0, toRow: rowId) }
            )
        }
    }

    // MARK: - Helpers

    private func pickerRow(_ label: String, value: String?, required: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 2) {
                    Text(label)
                    if required { Text("*").foregroundColor(.red) }
                }
                Spacer()
                Text(value ?? "请选择")
                    .foregroundColor(value == nil ? .secondary : .primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.primary)
    }

    private func numField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - Collapsible Section

private struct CollapsibleSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    var badge: Int = 0
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            if isExpanded {
                content()
            }
        } header: {
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                    if badge > 0 && !isExpanded {
                        Text("\(badge) 项已填")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.primary.opacity(0.8))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.primary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .textCase(nil)
        }
    }
}

// MARK: - Reusable Search Sheet

private struct RefSearchSheet<T: Identifiable>: View {
    let title: String
    let items: [T]
    let isSearching: Bool
    let display: (T) -> String
    var subtitle: ((T) -> String?)? = nil
    let onSearch: (String) -> Void
    let onSelect: (T) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if isSearching {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if items.isEmpty {
                    Text(searchText.isEmpty ? "暂无数据" : "未找到结果")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(display(item))
                                    .foregroundColor(.primary)
                                if let sub = subtitle?(item), !sub.isEmpty {
                                    Text(sub)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索")
            .onAppear { onSearch("") }
            .onChange(of: searchText) { newValue in
                onSearch(newValue)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class QuoteCreateViewModel: ObservableObject {
    @Published var activeSheet: QuoteFormSheet?
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var createdQuoteNo: String?

    @Published var isLoadingInitial = false
    @Published var isSubmitting = false
    @Published var isSearchingCustomers = false
    @Published var isSearchingMaterials = false
    @Published var isSearchingSuppliers = false
    @Published var isSearchingSizingProviders = false
    @Published var isLoadingBOM = false

    // Section expansion states
    @Published var isSpecsExpanded = false
    @Published var isProductionExpanded = false
    @Published var isFinishExpanded = false
    @Published var expandedMaterialRows: Set<UUID> = []

    // Material change confirmation
    @Published var showMaterialChangeConfirm = false
    var pendingMaterial: MaterialRef?

    // Cached reference data
    @Published var salespeople: [SalespersonRef] = []
    @Published var balanceTypes: [DictionaryItem] = []
    @Published var sourceTypes: [DictionaryItem] = []
    @Published var finishModes: [DictionaryItem] = []

    // API search results
    @Published var customerResults: [CustomerRef] = []
    @Published var materialResults: [MaterialRef] = []
    @Published var supplierResults: [SupplierRef] = []
    @Published var sizingProviderResults: [SupplierRef] = []

    // Local filters
    @Published var salespersonFilter = ""
    @Published var balanceTypeFilter = ""
    @Published var finishModeFilter = ""

    // ── Form fields ──

    @Published var customerName = ""
    @Published var customerGuid: String?
    @Published var linkMan = ""
    @Published var selectedSalesperson: SalespersonRef?
    @Published var orderType = "散单"
    @Published var selectedBalanceType: DictionaryItem?
    @Published var source = ""
    @Published var deliveryDate = Date()
    @Published var orderQty = ""
    @Published var quotePrice = ""
    @Published var materialCostDisplay = ""
    @Published var costPrice = ""
    @Published var remark = ""
    @Published var perRowCostMap: [UUID: Double] = [:]

    @Published var materialNo = ""
    @Published var materialName = ""
    @Published var materialGuid: String?
    @Published var materialDisplayLabel: String?

    @Published var width = ""
    @Published var reedId = ""
    @Published var fastenerRange = ""
    @Published var sideLength = ""
    @Published var warpWastagePercent = ""
    @Published var beamTotalEnd = ""
    @Published var warpDensity = ""
    @Published var weftDensity = ""

    @Published var weaveSpeed = ""
    @Published var weaveEff = ""
    @Published var weaveDayOutput = ""
    @Published var weaveDayCost = ""
    @Published var weaveDaySaleCost = ""
    @Published var sizingProviderName = ""
    @Published var sizingProviderGuid: String?

    @Published var weavePrice = ""
    @Published var sizingPrice = ""
    @Published var sandingPrice = ""
    @Published var stdWeavePrice = ""
    @Published var sampleCost = ""
    @Published var profitRate = ""

    @Published var materialRows: [MaterialRowData] = []
    @Published var finishRows: [FinishRowData] = []

    private let mode: QuoteFormMode
    private let service = QuoteAPIService.shared
    private let authManager = QuoteAuthManager.shared
    private let calculationConstants = CalculationConstants.defaultConstants
    private var searchTask: Task<Void, Never>?
    private var calculationCancellables: Set<AnyCancellable> = []
    private var didApplyInitialFormValues = false
    @Published var reedType: String?
    private var currency: String?
    private var materialTypeName: String?
    private var weaveType: String?

    init(mode: QuoteFormMode) {
        self.mode = mode
        setupDerivedCalculationBindings()
    }

    // MARK: - Computed

    var navigationTitle: String { mode.navigationTitle }

    var isValid: Bool {
        !customerName.isEmpty && authManager.currentUser != nil
    }

    var hasChanges: Bool {
        !customerName.isEmpty || !materialName.isEmpty
        || !materialRows.isEmpty || !finishRows.isEmpty
    }

    var specsFilledCount: Int {
        [width, reedId, fastenerRange, sideLength, warpWastagePercent, beamTotalEnd, warpDensity, weftDensity]
            .filter { !$0.isEmpty }.count
        + (reedTypeDisplay == "由物料档案带入" ? 0 : 1)
    }

    var reedTypeDisplay: String {
        let value = reedType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "由物料档案带入" : value
    }

    var productionFilledCount: Int {
        [weaveSpeed, weaveEff, weaveDayOutput, weaveDayCost, weaveDaySaleCost]
            .filter { !$0.isEmpty }.count
        + (sizingProviderName.isEmpty ? 0 : 1)
    }

    var filteredSalespeople: [SalespersonRef] {
        guard !salespersonFilter.isEmpty else { return salespeople }
        let kw = salespersonFilter.lowercased()
        return salespeople.filter {
            $0.salesName.lowercased().contains(kw)
            || ($0.salesNo?.lowercased().contains(kw) ?? false)
            || ($0.groupName?.lowercased().contains(kw) ?? false)
        }
    }

    var filteredBalanceTypes: [DictionaryItem] {
        guard !balanceTypeFilter.isEmpty else { return balanceTypes }
        let kw = balanceTypeFilter.lowercased()
        return balanceTypes.filter { $0.name.lowercased().contains(kw) }
    }

    var filteredFinishModes: [DictionaryItem] {
        guard !finishModeFilter.isEmpty else { return finishModes }
        let kw = finishModeFilter.lowercased()
        return finishModes.filter { $0.name.lowercased().contains(kw) }
    }

    private func setupDerivedCalculationBindings() {
        let triggers: [AnyPublisher<Void, Never>] = [
            $quotePrice.map { _ in () }.eraseToAnyPublisher(),
            $reedId.map { _ in () }.eraseToAnyPublisher(),
            $reedType.map { _ in () }.eraseToAnyPublisher(),
            $fastenerRange.map { _ in () }.eraseToAnyPublisher(),
            $sideLength.map { _ in () }.eraseToAnyPublisher(),
            $warpWastagePercent.map { _ in () }.eraseToAnyPublisher(),
            $beamTotalEnd.map { _ in () }.eraseToAnyPublisher(),
            $weftDensity.map { _ in () }.eraseToAnyPublisher(),
            $weaveSpeed.map { _ in () }.eraseToAnyPublisher(),
            $weaveEff.map { _ in () }.eraseToAnyPublisher(),
            $weaveDayOutput.map { _ in () }.eraseToAnyPublisher(),
            $weaveDayCost.map { _ in () }.eraseToAnyPublisher(),
            $sizingPrice.map { _ in () }.eraseToAnyPublisher(),
            $sandingPrice.map { _ in () }.eraseToAnyPublisher(),
            $materialRows.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(triggers)
            .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.recalculateDerivedPricing()
            }
            .store(in: &calculationCancellables)
    }

    private func recalculateDerivedPricing() {
        let calcResults = runMaterialCalculation()
        let materialCost = calcResults.map { $0.warpCost + $0.weftCost }

        updatePerRowCosts(from: calcResults)

        if let dayLaborCost = computedDailyLaborCost(materialCost: materialCost) {
            weaveDaySaleCost = fmt(dayLaborCost)
        } else {
            weaveDaySaleCost = ""
        }

        if let laborUnitCost = computedStandardLaborCost() {
            stdWeavePrice = fmt(laborUnitCost)
        } else {
            stdWeavePrice = ""
        }

        if let weaveUnitCost = computedWeaveUnitCost() {
            weavePrice = fmt(weaveUnitCost)
        } else {
            weavePrice = ""
        }

        let hasMaterialInputs = materialRows.contains { !isEmptyMaterialRow($0) }
        if hasMaterialInputs && materialCost == nil {
            materialCostDisplay = ""
            costPrice = ""
            profitRate = ""
            return
        }

        materialCostDisplay = materialCost.map { fmt($0) } ?? ""

        let sizingCost = dbl(sizingPrice) ?? 0
        let sandingCost = dbl(sandingPrice) ?? 0
        let weaveUnitCost = dbl(weavePrice) ?? 0
        let totalCost = (materialCost ?? 0) + sizingCost + sandingCost + weaveUnitCost
        costPrice = totalCost > 0 ? fmt(totalCost) : ""

        if let quote = dbl(quotePrice), quote > 0, totalCost > 0 {
            profitRate = fmt(((quote / totalCost) - 1) * 100)
        } else {
            profitRate = ""
        }
    }

    private func updatePerRowCosts(from calcResults: CalculationResults?) {
        var newMap: [UUID: Double] = [:]
        if let results = calcResults {
            let nonEmptyRows = materialRows.filter { !isEmptyMaterialRow($0) }
            for (idx, perResult) in results.perMaterialResults.enumerated() {
                guard idx < nonEmptyRows.count else { break }
                let row = nonEmptyRows[idx]
                let isWarp = normalizedUsage(row.usage) == "经纱"
                newMap[row.id] = isWarp ? perResult.warpCost : perResult.weftCost
            }
        }
        perRowCostMap = newMap
    }

    private func computedStandardLaborCost() -> Double? {
        guard let dayCost = dbl(weaveDaySaleCost),
              let dayOutput = dbl(weaveDayOutput),
              dayOutput > 0 else {
            return nil
        }

        return dayCost / dayOutput
    }

    private func computedDailyLaborCost(materialCost: Double?) -> Double? {
        guard let quote = dbl(quotePrice),
              let dayOutput = dbl(weaveDayOutput),
              dayOutput > 0,
              let materialCost else {
            return nil
        }

        let sizingCost = dbl(sizingPrice) ?? 0
        let sandingCost = dbl(sandingPrice) ?? 0
        let actualMargin = quote - materialCost - sizingCost - sandingCost
        return actualMargin * dayOutput
    }

    private func computedWeaveUnitCost() -> Double? {
        guard let dayMachineCost = dbl(weaveDayCost),
              let dayOutput = dbl(weaveDayOutput),
              dayOutput > 0 else {
            return nil
        }

        return dayMachineCost / dayOutput
    }

    private func runMaterialCalculation() -> CalculationResults? {
        let materials = buildCalculationMaterials()
        guard !materials.isEmpty else { return nil }

        let warpWastage = dbl(warpWastagePercent) ?? 0
        let warpShrinkageFactor = warpWastage < 100 ? 100.0 / (100.0 - warpWastage) : 1.0

        let results = CalculationResults()
        var alertMessage = ""
        let success = Calculator.calculate(
            boxNumber: reedId,
            threading: resolvedCalculationThreading(),
            fabricWidth: fastenerRange,
            edgeFinishing: sideLength.isEmpty ? "0" : sideLength,
            fabricShrinkage: String(format: "%.4f", warpShrinkageFactor),
            weftDensity: weftDensity,
            machineSpeed: weaveSpeed,
            efficiency: weaveEff,
            dailyLaborCost: "0",
            fixedCost: "0",
            materials: materials,
            constants: calculationConstants,
            calculationResults: results,
            warpEndsOverride: beamTotalEnd,
            alertMessage: &alertMessage
        )

        return success ? results : nil
    }

    private func calculatedMaterialCost() -> Double? {
        guard let results = runMaterialCalculation() else { return nil }
        return results.warpCost + results.weftCost
    }

    private func computePerRowMaterialCosts() -> [UUID: (yarnUseQty: Double, dtlYarnCost: Double)] {
        var costMap: [UUID: (yarnUseQty: Double, dtlYarnCost: Double)] = [:]
        guard let results = runMaterialCalculation() else { return costMap }

        let nonEmptyRows = materialRows.filter { !isEmptyMaterialRow($0) }
        for (idx, perResult) in results.perMaterialResults.enumerated() {
            guard idx < nonEmptyRows.count else { break }
            let row = nonEmptyRows[idx]
            let isWarp = normalizedUsage(row.usage) == "经纱"
            costMap[row.id] = (
                yarnUseQty: isWarp ? perResult.warpWeight : perResult.weftWeight,
                dtlYarnCost: isWarp ? perResult.warpCost : perResult.weftCost
            )
        }
        return costMap
    }

    private func buildCalculationMaterials() -> [Material] {
        var materials = materialRows.compactMap { row -> Material? in
            guard !isEmptyMaterialRow(row) else { return nil }

            let isWarp = normalizedUsage(row.usage) == "经纱"
            let yarnType = resolvedYarnType(for: row)
            let yarnValue = resolvedYarnValue(for: row, yarnType: yarnType)
            let yarnPrice = resolvedCalculationPrice(for: row)
            let ratio = resolvedMaterialRatio(for: row)
            let materialName = row.materialName.isEmpty
                ? (row.materialNo.isEmpty ? row.usage : row.materialNo)
                : row.materialName

            return Material(
                name: materialName,
                warpYarnValue: isWarp ? yarnValue : "0",
                warpYarnTypeSelection: isWarp ? yarnType : .dNumber,
                weftYarnValue: isWarp ? "0" : yarnValue,
                weftYarnTypeSelection: isWarp ? .dNumber : yarnType,
                warpYarnPrice: isWarp ? yarnPrice : "0",
                weftYarnPrice: isWarp ? "0" : yarnPrice,
                warpRatio: isWarp ? ratio : "0",
                weftRatio: isWarp ? "0" : ratio,
                ratio: "1"
            )
        }

        ensureDirectionalRatios(on: &materials)
        return materials
    }

    private func isEmptyMaterialRow(_ row: MaterialRowData) -> Bool {
        [
            row.materialName,
            row.materialNo,
            row.denierNum,
            row.patternPerQty,
            row.perCent,
            row.unitPrice,
            row.yarnPrice,
            row.yarnCount,
            row.remark
        ].allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func resolvedYarnType(for row: MaterialRowData) -> YarnType {
        if let denier = dbl(row.denierNum), denier > 0 {
            return .dNumber
        }

        let rawValue = row.yarnCount.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if rawValue.contains("d") || rawValue.contains("旦") {
            return .dNumber
        }

        return .yarnCount
    }

    private func resolvedYarnValue(for row: MaterialRowData, yarnType: YarnType) -> String {
        switch yarnType {
        case .dNumber:
            if let denier = dbl(row.denierNum), denier > 0 {
                return fmt(denier)
            }
            if let numeric = extractedNumericValue(from: row.yarnCount), numeric > 0 {
                return fmt(numeric)
            }
        case .yarnCount:
            if let numeric = extractedNumericValue(from: row.yarnCount), numeric > 0 {
                return fmt(numeric)
            }
        }

        return "0"
    }

    private func resolvedCalculationPrice(for row: MaterialRowData) -> String {
        if let unitPrice = dbl(row.unitPrice), unitPrice > 0 {
            return fmt(unitPrice)
        }
        return "0"
    }

    private func resolvedMaterialRatio(for row: MaterialRowData) -> String {
        if let percent = dbl(row.perCent), percent > 0 {
            return fmt(percent)
        }
        if let pattern = int(row.patternPerQty), pattern > 0 {
            return "\(pattern)"
        }
        return "1"
    }

    private func extractedNumericValue(from rawValue: String) -> Double? {
        let cleaned = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if let direct = Double(cleaned) {
            return direct
        }

        let pattern = #"[-+]?[0-9]*\.?[0-9]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
        guard let match = regex.firstMatch(in: cleaned, range: range),
              let matchedRange = Range(match.range, in: cleaned) else {
            return nil
        }

        return Double(String(cleaned[matchedRange]))
    }

    private func resolvedCalculationThreading() -> String {
        guard let reedType,
              let numeric = extractedNumericValue(from: reedType),
              numeric > 0 else {
            return ""
        }

        return fmt(numeric)
    }

    private func ensureDirectionalRatios(on materials: inout [Material]) {
        let totalWarp = materials.map { Double($0.warpRatio ?? "0") ?? 0 }.reduce(0, +)
        let totalWeft = materials.map { Double($0.weftRatio ?? "0") ?? 0 }.reduce(0, +)
        let warpIndices = materials.indices.filter { isWarpMaterial(materials[$0]) }
        let weftIndices = materials.indices.filter { isWeftMaterial(materials[$0]) }

        if totalWarp == 0 {
            if warpIndices.isEmpty {
                if let firstIndex = materials.indices.first {
                    materials[firstIndex].warpRatio = "0.001"
                }
            } else {
                for index in warpIndices {
                    materials[index].warpRatio = "1"
                }
            }
        }

        if totalWeft == 0 {
            if weftIndices.isEmpty {
                if let firstIndex = materials.indices.first {
                    materials[firstIndex].weftRatio = "0.001"
                }
            } else {
                for index in weftIndices {
                    materials[index].weftRatio = "1"
                }
            }
        }
    }

    private func isWarpMaterial(_ material: Material) -> Bool {
        (Double(material.warpYarnValue) ?? 0) > 0 || (Double(material.warpYarnPrice) ?? 0) > 0
    }

    private func isWeftMaterial(_ material: Material) -> Bool {
        (Double(material.weftYarnValue) ?? 0) > 0 || (Double(material.weftYarnPrice) ?? 0) > 0
    }

    // MARK: - Load Initial

    func loadInitialData() async {
        isLoadingInitial = true
        async let s = service.fetchSalespeople()
        async let b = service.fetchDictionary(typeCode: "BalanceType")
        async let o = service.fetchDictionary(typeCode: "OrderSource")
        async let f = service.fetchDictionary(typeCode: "FinishingMode")

        do {
            let (sp, bt, os, fm) = try await (s, b, o, f)
            salespeople = sp
            balanceTypes = bt
            sourceTypes = os
            finishModes = fm
            autoSelectSalesperson(from: sp)
        } catch {
            alertMessage = "加载基础数据失败: \(error.localizedDescription)"
            showAlert = true
        }
        applyInitialFormValuesIfNeeded()
        isLoadingInitial = false
    }

    private func autoSelectSalesperson(from list: [SalespersonRef]) {
        if let sales = authManager.salesInfo {
            selectedSalesperson = list.first { $0.guid == sales.salesGuid }
                ?? SalespersonRef(
                    guid: sales.salesGuid,
                    salesNo: sales.salesNo,
                    salesName: sales.salesName,
                    groupName: nil,
                    groupGuid: sales.salesGroupGuid
                )
        }
    }

    private func applyInitialFormValuesIfNeeded() {
        guard !didApplyInitialFormValues else { return }
        let detail: QuoteDetail
        switch mode {
        case .create:
            didApplyInitialFormValues = true
            return
        case .edit(let existingDetail), .reference(let existingDetail):
            detail = existingDetail
        }

        customerName = detail.customerName ?? ""
        customerGuid = detail.customerGuid
        linkMan = detail.linkMan ?? ""
        if let salesGuid = detail.salesGuid,
           let matchedSales = salespeople.first(where: { $0.guid == salesGuid }) {
            selectedSalesperson = matchedSales
        } else if let salesName = detail.salesName, !salesName.isEmpty {
            selectedSalesperson = SalespersonRef(
                guid: detail.salesGuid ?? "",
                salesNo: nil,
                salesName: salesName,
                groupName: nil,
                groupGuid: detail.salesGroupGuid
            )
        }

        if let balanceType = detail.balanceType, !balanceType.isEmpty {
            selectedBalanceType = balanceTypes.first(where: { $0.name == balanceType })
                ?? DictionaryItem(code: balanceType, name: balanceType)
        }
        source = detail.source ?? ""
        if !source.isEmpty && !sourceTypes.contains(where: { $0.name == source }) {
            sourceTypes.append(DictionaryItem(code: source, name: source))
        }
        if let deliveryText = detail.deliveryDate,
           let parsedDate = Self.dateFormatter.date(from: deliveryText) {
            deliveryDate = parsedDate
        }
        if let existingOrderType = detail.orderType,
           ["散单", "样单", "翻单"].contains(existingOrderType) {
            orderType = existingOrderType
        }
        orderQty = fmt(detail.orderQty)
        quotePrice = fmt(detail.price)
        costPrice = fmt(detail.costPrice)
        remark = detail.remark ?? ""

        materialNo = detail.materialNo ?? ""
        materialName = detail.materialName ?? ""
        materialGuid = detail.materialGuid
        materialDisplayLabel = [detail.materialNo, detail.materialName]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")

        width = fmt(detail.width)
        reedId = fmt(detail.reedId)
        fastenerRange = fmt(detail.fastenerRange)
        sideLength = fmt(detail.sideLength)
        warpWastagePercent = fmt(detail.warpWastagePercent)
        beamTotalEnd = detail.beamTotalEnd.map { "\($0)" } ?? ""
        warpDensity = fmt(detail.warpDensity)
        weftDensity = fmt(detail.weftDensity)

        weaveSpeed = fmt(detail.weaveSpeed)
        weaveEff = fmt(detail.weaveEff)
        weaveDayOutput = fmt(detail.weaveDayOutput)
        weaveDayCost = fmt(detail.weaveDayCost)
        weaveDaySaleCost = fmt(detail.weaveDaySaleCost)
        sizingProviderName = detail.sizingProviderName ?? ""
        sizingProviderGuid = detail.sizingProviderGuid

        weavePrice = fmt(detail.weavePrice)
        sizingPrice = fmt(detail.sizingPrice)
        sandingPrice = fmt(detail.sandingPrice)
        stdWeavePrice = fmt(detail.stdWeavePrice)
        sampleCost = fmt(detail.sampleCost)
        profitRate = fmt(detail.profitRate)

        reedType = detail.reedType
        currency = detail.currency
        materialTypeName = detail.materialTypeName
        weaveType = detail.weaveType

        materialRows = detail.materials?.map { row in
            MaterialRowData(
                usage: normalizedUsage(row.usage),
                materialName: row.materialName ?? "",
                materialNo: row.materialNo ?? "",
                denierNum: fmt(row.denierNum),
                patternPerQty: row.patternPerQty.map { "\($0)" } ?? "",
                perCent: fmt(row.perCent),
                unitPrice: fmt(row.unitPrice),
                yarnPrice: fmt(row.yarnPrice),
                providerName: row.providerName ?? "",
                providerNo: row.providerNo ?? "",
                yarnCount: row.yarnCount ?? "",
                remark: row.remark ?? ""
            )
        } ?? []

        finishRows = detail.finishDetails?.map { row in
            FinishRowData(
                finishMode: row.finishMode ?? "",
                count: row.count.map { "\($0)" } ?? "",
                price: fmt(row.price),
                amount: fmt(row.amount)
            )
        } ?? []

        // In edit mode, expand specs/production if they have data
        if specsFilledCount > 0 { isSpecsExpanded = true }
        if productionFilledCount > 0 { isProductionExpanded = true }
        if !finishRows.isEmpty { isFinishExpanded = true }

        didApplyInitialFormValues = true
    }

    // MARK: - BOM Auto-fill

    func fetchAndApplyBOM(materialGuid: String) async {
        isLoadingBOM = true
        do {
            let bom = try await service.fetchMaterialBOM(materialGuid: materialGuid)
            materialRows = bom.yarns.map { yarn in
                MaterialRowData(
                    usage: yarn.usageDisplayName,
                    materialName: yarn.materialName ?? "",
                    materialNo: yarn.materialNo ?? "",
                    denierNum: yarn.denierNum.map { fmt($0) } ?? "",
                    patternPerQty: yarn.patternPerQty.map { "\($0)" } ?? "",
                    perCent: yarn.percent.map { fmt($0) } ?? "",
                    unitPrice: "",
                    yarnPrice: "",
                    providerName: yarn.suggestedSupplier?.name ?? "",
                    providerNo: yarn.suggestedSupplier?.code ?? "",
                    yarnCount: yarn.yarnCount ?? "",
                    remark: ""
                )
            }
        } catch {
            alertMessage = "加载原料配方失败: \(error.localizedDescription)"
            showAlert = true
        }
        isLoadingBOM = false
    }

    // MARK: - Debounced Search

    func searchCustomers(keyword: String) {
        debouncedSearch(keyword: keyword, loading: \.isSearchingCustomers, results: \.customerResults) {
            try await self.service.searchCustomers(keyword: keyword)
        }
    }

    func searchMaterials(keyword: String) {
        debouncedSearch(keyword: keyword, loading: \.isSearchingMaterials, results: \.materialResults) {
            try await self.service.searchMaterials(keyword: keyword)
        }
    }

    func searchSuppliers(keyword: String) {
        debouncedSearch(keyword: keyword, loading: \.isSearchingSuppliers, results: \.supplierResults) {
            try await self.service.searchSuppliers(keyword: keyword)
        }
    }

    func searchSizingProviders(keyword: String) {
        debouncedSearch(keyword: keyword, loading: \.isSearchingSizingProviders, results: \.sizingProviderResults) {
            try await self.service.searchSizingProviders(keyword: keyword)
        }
    }

    private func debouncedSearch<T>(
        keyword: String,
        loading: ReferenceWritableKeyPath<QuoteCreateViewModel, Bool>,
        results: ReferenceWritableKeyPath<QuoteCreateViewModel, [T]>,
        fetch: @escaping () async throws -> [T]
    ) {
        searchTask?.cancel()
        self[keyPath: loading] = true
        searchTask = Task {
            if !keyword.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            guard !Task.isCancelled else { return }
            do {
                self[keyPath: results] = try await fetch()
            } catch {
                if !Task.isCancelled { self[keyPath: results] = [] }
            }
            self[keyPath: loading] = false
        }
    }

    // MARK: - Apply Selections

    func applyCustomer(_ c: CustomerRef) {
        customerName = c.name
        customerGuid = c.guid
        linkMan = c.contactPerson ?? ""
        activeSheet = nil
    }

    func applyMaterial(_ m: MaterialRef) {
        let isEditing: Bool
        if case .edit = mode { isEditing = true } else { isEditing = false }
        let hasMaterialRows = !materialRows.isEmpty

        if isEditing && hasMaterialRows && materialGuid != m.guid {
            pendingMaterial = m
            showMaterialChangeConfirm = true
            activeSheet = nil
            return
        }

        applyMaterialFields(m)
        activeSheet = nil

        if let guid = m.guid as String? {
            Task { await fetchAndApplyBOM(materialGuid: guid) }
        }
    }

    func confirmMaterialChange(_ m: MaterialRef) {
        applyMaterialFields(m)
        pendingMaterial = nil
        if let guid = m.guid as String? {
            Task { await fetchAndApplyBOM(materialGuid: guid) }
        }
    }

    private func applyMaterialFields(_ m: MaterialRef) {
        materialNo = m.materialNo ?? ""
        materialName = m.materialName ?? ""
        materialGuid = m.guid
        materialDisplayLabel = m.displayLabel

        width = m.width.map { fmt($0) } ?? ""
        warpDensity = m.warpDensity.map { fmt($0) } ?? ""
        weftDensity = m.weftDensity.map { fmt($0) } ?? ""
        beamTotalEnd = m.beamTotalEnd.map { "\($0)" } ?? ""
        warpWastagePercent = m.warpWastagePercent.map { fmt($0) } ?? ""
        reedId = m.reedId.map { fmt($0) } ?? ""
        fastenerRange = m.fastenerRange.map { fmt($0) } ?? ""
        reedType = m.reedType
        sideLength = m.sideLength.map { fmt($0) } ?? ""

        weaveSpeed = m.weaveSpeed.map { fmt($0) } ?? ""
        weaveEff = m.weaveEff.map { fmt($0) } ?? ""
        weaveDayOutput = m.weaveDayOutput.map { fmt($0) } ?? ""
        weaveDayCost = m.weaveDayCost.map { fmt($0) } ?? ""

        weavePrice = m.weavePrice.map { fmt($0) } ?? ""
        sizingPrice = m.sizingPrice.map { fmt($0) } ?? ""
    }

    func applySalesperson(_ s: SalespersonRef) {
        selectedSalesperson = s
        activeSheet = nil
    }

    func applySizingProvider(_ p: SupplierRef) {
        sizingProviderName = p.name
        sizingProviderGuid = p.guid
        activeSheet = nil
    }

    func applySupplier(_ s: SupplierRef, toRow rowId: UUID) {
        if let idx = materialRows.firstIndex(where: { $0.id == rowId }) {
            materialRows[idx].providerName = s.name
            materialRows[idx].providerNo = s.code ?? ""
        }
        activeSheet = nil
    }

    func applyFinishMode(_ d: DictionaryItem, toRow rowId: UUID) {
        if let idx = finishRows.firstIndex(where: { $0.id == rowId }) {
            finishRows[idx].finishMode = d.name
        }
        activeSheet = nil
    }

    // MARK: - Submit

    func submit() async {
        guard let creator = authManager.currentUser else {
            alertMessage = "当前未登录，无法保存报价单"
            showAlert = true
            return
        }

        isSubmitting = true

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let perRowCosts = computePerRowMaterialCosts()

        let request = QuoteCreateRequest(
            customerName: customerName,
            customerGuid: customerGuid,
            linkMan: linkMan.isEmpty ? nil : linkMan,
            salesGuid: emptyToNil(selectedSalesperson?.guid),
            salesName: selectedSalesperson?.salesName,
            salesGroupGuid: emptyToNil(selectedSalesperson?.groupGuid),
            source: source.isEmpty ? nil : source,
            materialNo: materialNo.isEmpty ? nil : materialNo,
            materialName: materialName.isEmpty ? nil : materialName,
            materialGuid: materialGuid,
            materialTypeName: materialTypeName,
            weaveType: weaveType,
            width: dbl(width),
            beamTotalEnd: int(beamTotalEnd),
            warpDensity: dbl(warpDensity),
            weftDensity: dbl(weftDensity),
            warpWastagePercent: dbl(warpWastagePercent),
            reedId: dbl(reedId),
            fastenerRange: dbl(fastenerRange),
            reedType: reedType,
            sideLength: dbl(sideLength),
            weaveSpeed: dbl(weaveSpeed),
            weaveEff: dbl(weaveEff),
            weaveDayOutput: dbl(weaveDayOutput),
            weaveDayCost: dbl(weaveDayCost),
            weaveDaySaleCost: dbl(weaveDaySaleCost),
            price: dbl(quotePrice),
            costPrice: dbl(costPrice),
            weavePrice: dbl(weavePrice),
            sizingPrice: dbl(sizingPrice),
            sandingPrice: dbl(sandingPrice),
            stdWeavePrice: dbl(stdWeavePrice),
            sampleCost: dbl(sampleCost),
            orderQty: dbl(orderQty),
            orderType: orderType,
            balanceType: selectedBalanceType?.name,
            currency: currency,
            deliveryDate: dateFmt.string(from: deliveryDate),
            profitRate: dbl(profitRate),
            sizingProviderName: sizingProviderName.isEmpty ? nil : sizingProviderName,
            sizingProviderGuid: sizingProviderGuid,
            remark: remark.isEmpty ? nil : remark,
            creator: creator,
            materials: materialRows.map { row in
                let costs = perRowCosts[row.id]
                return QuoteCreateMaterialRow(
                    materialNo: row.materialNo.isEmpty ? nil : row.materialNo,
                    materialName: row.materialName.isEmpty ? nil : row.materialName,
                    usage: row.usage,
                    denierNum: dbl(row.denierNum),
                    patternPerQty: Int(row.patternPerQty),
                    perCent: dbl(row.perCent),
                    unitPrice: dbl(row.unitPrice),
                    yarnPrice: dbl(row.yarnPrice),
                    providerNo: row.providerNo.isEmpty ? nil : row.providerNo,
                    providerName: row.providerName.isEmpty ? nil : row.providerName,
                    yarnCount: row.yarnCount.isEmpty ? nil : row.yarnCount,
                    remark: row.remark.isEmpty ? nil : row.remark,
                    yarnUseQty: costs?.yarnUseQty,
                    dtlYarnCost: costs?.dtlYarnCost
                )
            },
            finishDetails: finishRows.compactMap { row in
                guard !row.finishMode.isEmpty else { return nil }
                return QuoteCreateFinishRow(
                    finishMode: row.finishMode,
                    count: int(row.count),
                    price: dbl(row.price),
                    amount: dbl(row.amount)
                )
            }
        )

        do {
            let response: QuoteCreateResponse
            if let quoteNo = mode.quoteNo {
                response = try await service.updateQuote(quoteNo: quoteNo, request: request)
            } else {
                response = try await service.createQuote(request)
            }
            createdQuoteNo = response.quoteNo
            alertMessage = "报价单 \(response.quoteNo) \(mode.successMessagePrefix)成功"
        } catch {
            alertMessage = "\(mode.successMessagePrefix)失败: \(error.localizedDescription)"
        }

        isSubmitting = false
        showAlert = true
    }

    // MARK: - Formatting Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func normalizedUsage(_ usage: String?) -> String {
        guard let usage = usage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !usage.isEmpty else {
            return "纬纱"
        }

        if usage == "j" || usage.contains("经") || usage.contains("warp") {
            return "经纱"
        }

        return "纬纱"
    }

    private func fmt(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    private func fmt(_ v: Double?) -> String {
        guard let v else { return "" }
        return fmt(v)
    }

    private func dbl(_ s: String) -> Double? {
        s.isEmpty ? nil : Double(s)
    }

    private func int(_ s: String) -> Int? {
        s.isEmpty ? nil : Int(s)
    }

    private func emptyToNil(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
