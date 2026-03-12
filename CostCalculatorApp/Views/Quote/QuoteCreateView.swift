//
//  QuoteCreateView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-10.
//

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

    var navigationTitle: String {
        switch self {
        case .create:
            return "新建报价单"
        case .edit:
            return "编辑报价单"
        }
    }

    var successMessagePrefix: String {
        switch self {
        case .create:
            return "创建"
        case .edit:
            return "更新"
        }
    }

    var quoteNo: String? {
        switch self {
        case .create:
            return nil
        case .edit(let detail):
            return detail.quoteNo
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
    }

    // MARK: - Form

    private var formContent: some View {
        Form {
            basicInfoSection
            materialSection
            specsSection
            productionSection
            pricingSection
            materialsDetailSection
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
            if vm.materialGuid != nil {
                Text("选择物料后，规格和生产参数已自动填充，可手动修改")
            }
        }
    }

    // MARK: - Specs

    private var specsSection: some View {
        Section("规格参数") {
            numField("成品门幅", text: $vm.width)
            numField("筘号", text: $vm.reedId)
            numField("筘幅", text: $vm.fastenerRange)
            numField("废边长度(cm)", text: $vm.sideLength)
            numField("经缩%", text: $vm.warpWastagePercent)
            numField("总经根数", text: $vm.beamTotalEnd)
            numField("经密", text: $vm.warpDensity)
            numField("纬密", text: $vm.weftDensity)
        }
    }

    // MARK: - Production

    private var productionSection: some View {
        Section("生产参数") {
            numField("车速", text: $vm.weaveSpeed)
            numField("综合效率%", text: $vm.weaveEff)
            numField("日产量", text: $vm.weaveDayOutput)
            numField("日工费", text: $vm.weaveDaySaleCost)

            pickerRow("浆纱供应商", value: vm.sizingProviderName.isEmpty ? nil : vm.sizingProviderName) {
                vm.activeSheet = .sizingProvider
            }
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        Section("价格信息") {
            numField("织价", text: $vm.weavePrice)
            numField("浆纱单价", text: $vm.sizingPrice)
            numField("磨毛单价", text: $vm.sandingPrice)
            numField("标准工费", text: $vm.stdWeavePrice)
            numField("小样费用", text: $vm.sampleCost)
            numField("利润率%", text: $vm.profitRate)
        }
    }

    // MARK: - Materials Detail

    private var materialsDetailSection: some View {
        Section {
            ForEach($vm.materialRows) { $row in
                DisclosureGroup {
                    materialRowFields(row: $row)
                } label: {
                    materialRowLabel(row: $row.wrappedValue)
                }
            }
            .onDelete { vm.materialRows.remove(atOffsets: $0) }

            Button {
                vm.materialRows.append(MaterialRowData())
            } label: {
                Label("添加原料", systemImage: "plus.circle")
            }
        } header: {
            Text("原料明细")
        }
    }

    private func materialRowLabel(row: MaterialRowData) -> some View {
        HStack {
            Text(row.usage)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(row.usage == "经纱" ? AppTheme.Colors.primary : AppTheme.Colors.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (row.usage == "经纱" ? AppTheme.Colors.primary : AppTheme.Colors.accent).opacity(0.1)
                )
                .cornerRadius(4)

            Text(row.materialName.isEmpty ? "未命名" : row.materialName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            if !row.unitPrice.isEmpty {
                Text("¥\(row.unitPrice)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func materialRowFields(row: Binding<MaterialRowData>) -> some View {
        Picker("用途", selection: row.usage) {
            Text("经纱").tag("经纱")
            Text("纬纱").tag("纬纱")
        }
        .pickerStyle(.segmented)

        TextField("原料名称", text: row.materialName)
        TextField("原料编号", text: row.materialNo)
        numField("D数", text: row.denierNum)
        numField("根数", text: row.patternPerQty)
        numField("占比%", text: row.perCent)
        numField("单价", text: row.unitPrice)
        numField("加工单价", text: row.yarnPrice)

        Button {
            vm.activeSheet = .supplier(row.wrappedValue.id)
        } label: {
            HStack {
                Text("供应商")
                Spacer()
                Text(row.wrappedValue.providerName.isEmpty ? "请选择" : row.wrappedValue.providerName)
                    .foregroundColor(row.wrappedValue.providerName.isEmpty ? .secondary : .primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.primary)

        TextField("纱支", text: row.yarnCount)
        TextField("备注", text: row.remark)
    }

    // MARK: - Finish Detail

    private var finishDetailSection: some View {
        Section {
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
        } header: {
            Text("后整理明细")
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
                subtitle: { [$0.component, $0.width.map { "门幅\($0)" }].compactMap { $0 }.joined(separator: " · ") },
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
    @Published var remark = ""

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
    private var searchTask: Task<Void, Never>?
    private var didApplyInitialFormValues = false
    private var reedType: String?
    private var currency: String?
    private var materialTypeName: String?
    private var weaveType: String?

    init(mode: QuoteFormMode) {
        self.mode = mode
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
        guard case .edit(let detail) = mode else {
            didApplyInitialFormValues = true
            return
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

        didApplyInitialFormValues = true
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

        weaveSpeed = m.weaveSpeed.map { fmt($0) } ?? ""
        weaveEff = m.weaveEff.map { fmt($0) } ?? ""
        weaveDayOutput = m.weaveDayOutput.map { fmt($0) } ?? ""

        weavePrice = m.weavePrice.map { fmt($0) } ?? ""
        sizingPrice = m.sizingPrice.map { fmt($0) } ?? ""

        activeSheet = nil
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
                QuoteCreateMaterialRow(
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
                    remark: row.remark.isEmpty ? nil : row.remark
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
