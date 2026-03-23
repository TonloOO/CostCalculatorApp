//
//  QuoteModels.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import Foundation

// MARK: - Paginated Response

struct PaginatedResponse<T: Codable>: Codable {
    let total: Int
    let page: Int
    let page_size: Int
    let data: [T]
    
    var pageSize: Int { page_size }
    var totalPages: Int { max(1, Int(ceil(Double(total) / Double(page_size)))) }
    var hasNextPage: Bool { page < totalPages }
}

// MARK: - Shared Status

enum QuoteStatus: Int, CaseIterable {
    case all = -1
    case editing = 0
    case submitted = 1
    case approved = 2

    var label: String {
        switch self {
        case .all: return "全部"
        case .editing: return "编辑中"
        case .submitted: return "已提交"
        case .approved: return "已审核"
        }
    }

    var queryValue: Int? {
        self == .all ? nil : rawValue
    }

    var backendLabel: String? {
        switch self {
        case .all: return nil
        case .editing: return "编辑"
        case .submitted: return "提交"
        case .approved: return "已审核"
        }
    }

    init?(backendLabel: String?) {
        switch backendLabel {
        case "编辑", "编辑中": self = .editing
        case "提交", "已提交": self = .submitted
        case "已审核": self = .approved
        default: return nil
        }
    }
}

// MARK: - Quote Overview

struct QuoteOverview: Codable, Identifiable {
    let quoteNo: String
    let customerName: String?
    let materialNo: String?
    let materialName: String?
    let beamTotalEnd: Int?
    let width: Double?
    let orderQty: Double?
    let weftDensity: Double?
    let weaveDaySaleCost: Double?
    let price: Double?
    let weaveDayOutput: Double?
    let quoteTime: String?
    let status: String?
    let costPrice: Double?
    let profitRate: Double?
    let fastenerRange: Double?
    let materials: [QuoteMaterial]?
    
    var id: String { quoteNo }

    var normalizedStatus: QuoteStatus? {
        QuoteStatus(backendLabel: status)
    }
}

struct QuoteMaterial: Codable, Identifiable {
    let usage: String?
    let materialName: String?
    let providerName: String?
    let unitPrice: Double?
    let yarnUseQty: Double?
    let dtlYarnCost: Double?
    
    var id: String { "\(usage ?? "")-\(materialName ?? "")-\(providerName ?? "")-\(unitPrice ?? 0)-\(yarnUseQty ?? 0)-\(dtlYarnCost ?? 0)" }
}

// MARK: - Quote Approval

struct QuoteApproval: Codable, Identifiable {
    let status: String
    let quoteNo: String
    let materialName: String?
    let orderQty: Double?
    let customerName: String?
    let quoteTime: String?
    let price: Double?
    let weaveDaySaleCost: Double?
    let costPrice: Double?
    let weavePrice: Double?
    let sizingPrice: Double?
    let sizingProviderName: String?
    let yarnPrice: Double?
    let profitRate: Double?
    let linkMan: String?
    let remark: String?
    let width: Double?
    let beamTotalEnd: Int?

    var id: String { quoteNo }

    var normalizedStatus: QuoteStatus? {
        QuoteStatus(backendLabel: status)
    }
}

enum QuoteApprovalAction: String, Codable {
    case submit
    case approve
    case reject
    case revoke

    var label: String {
        switch self {
        case .submit: return "提交"
        case .approve: return "审核通过"
        case .reject: return "驳回"
        case .revoke: return "撤销审核"
        }
    }

    static func actions(for status: QuoteStatus?) -> [QuoteApprovalAction] {
        switch status {
        case .editing:
            return [.submit]
        case .submitted:
            return [.approve, .reject]
        case .approved:
            return [.revoke]
        case .all, .none:
            return []
        }
    }
}

struct QuoteApprovalActionRequest: Codable {
    let action: QuoteApprovalAction
    let operatorName: String

    enum CodingKeys: String, CodingKey {
        case action
        case operatorName = "operator"
    }
}

struct QuoteApprovalActionResponse: Codable {
    let quoteNo: String
    let previousStatus: String
    let currentStatus: String
    let action: QuoteApprovalAction
    let orderSyncTriggered: Bool
}

extension QuoteApprovalActionResponse {
    var summaryText: String {
        switch action {
        case .submit:
            return "提交成功"
        case .approve:
            return "审批成功"
        case .reject:
            return "驳回成功"
        case .revoke:
            return "撤销成功"
        }
    }
}

// MARK: - Quote Detail

struct QuoteDetail: Codable {
    let quoteNo: String
    let customerName: String?
    let customerGuid: String?
    let materialNo: String?
    let materialName: String?
    let materialGuid: String?
    let orderType: String?
    let balanceType: String?
    let salesName: String?
    let salesGuid: String?
    let salesGroupGuid: String?
    let linkMan: String?
    let remark: String?
    let status: String?
    let quoteTime: String?
    let deliveryDate: String?
    let source: String?
    let materialTypeName: String?
    let weaveType: String?

    let width: Double?
    let reedId: Double?
    let fastenerRange: Double?
    let reedType: String?
    let sideLength: Double?
    let warpWastagePercent: Double?
    let beamTotalEnd: Int?
    let warpDensity: Double?
    let weftDensity: Double?

    let orderQty: Double?

    let price: Double?
    let costPrice: Double?
    let yarnPrice: Double?
    let weavePrice: Double?
    let sizingPrice: Double?
    let sandingPrice: Double?
    let sampleCost: Double?
    let stdWeavePrice: Double?

    let weaveSpeed: Double?
    let weaveEff: Double?
    let weaveDayOutput: Double?
    let weaveDayCost: Double?
    let weaveDaySaleCost: Double?

    let dyeCost: Double?
    let sizingCost: Double?
    let weaveCost: Double?
    let finishCost: Double?
    let testCost: Double?
    let yarnCost: Double?
    let otherCost: Double?
    let repairCost: Double?
    let managerCost: Double?
    let traficCost: Double?
    let packageCost: Double?
    let traficPrice: Double?

    let profitRate: Double?
    let sizingProviderName: String?
    let sizingProviderGuid: String?
    let currency: String?
    let amount: Double?
    let finallyPrice: Double?

    let materials: [QuoteDetailMaterial]?
    let finishDetails: [QuoteDetailFinish]?

    var normalizedStatus: QuoteStatus? {
        QuoteStatus(backendLabel: status)
    }
}

struct QuoteDetailMaterial: Codable, Identifiable {
    let rowNo: Int?
    let usage: String?
    let materialNo: String?
    let materialName: String?
    let denierNum: Double?
    let yarnUseQty: Double?
    let patternPerQty: Int?
    let orderYarnQty: Double?
    let perCent: Double?
    let providerNo: String?
    let providerName: String?
    let unitPrice: Double?
    let yarnPrice: Double?
    let yarnAmount: Double?
    let dtlYarnCost: Double?
    let yarnCount: String?
    let remark: String?

    var id: Int { rowNo ?? 0 }
}

struct QuoteDetailFinish: Codable, Identifiable {
    let finishMode: String?
    let count: Int?
    let price: Double?
    let amount: Double?

    var id: String { finishMode ?? UUID().uuidString }
}

// MARK: - Reference Data

struct CustomerRef: Codable, Identifiable, Hashable {
    let guid: String
    let code: String?
    let name: String
    let abbName: String?
    let contactPerson: String?

    var id: String { guid }
}

struct SalespersonRef: Codable, Identifiable, Hashable {
    let guid: String
    let salesNo: String?
    let salesName: String
    let groupName: String?
    let groupGuid: String?

    var id: String { guid }
}

struct SupplierRef: Codable, Identifiable, Hashable {
    let guid: String
    let code: String?
    let name: String

    var id: String { guid }
}

struct DictionaryItem: Codable, Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}

struct MaterialRef: Codable, Identifiable, Hashable {
    let guid: String
    let materialNo: String?
    let materialName: String?
    let component: String?
    let width: Double?
    let warpDensity: Double?
    let weftDensity: Double?
    let beamTotalEnd: Int?
    let warpWastagePercent: Double?
    let category: String?
    let reedId: Double?
    let fastenerRange: Double?
    let reedType: String?
    let sideLength: Double?
    let weaveSpeed: Double?
    let weaveEff: Double?
    let weaveDayOutput: Double?
    let weavePrice: Double?
    let sizingPrice: Double?
    let weaveDayCost: Double?

    var id: String { guid }

    var displayLabel: String {
        let no = materialNo ?? ""
        let name = materialName ?? ""
        if no.isEmpty { return name }
        if name.isEmpty { return no }
        return "\(no) · \(name)"
    }
}

// MARK: - Quote Creation

struct QuoteCreateMaterialRow: Codable {
    var materialNo: String?
    var materialName: String?
    var usage: String
    var denierNum: Double?
    var patternPerQty: Int?
    var perCent: Double?
    var unitPrice: Double?
    var yarnPrice: Double?
    var providerNo: String?
    var providerName: String?
    var yarnCount: String?
    var remark: String?
    var yarnUseQty: Double?
    var dtlYarnCost: Double?
}

struct QuoteCreateFinishRow: Codable {
    var finishMode: String
    var count: Int?
    var price: Double?
    var amount: Double?
}

struct QuoteCreateRequest: Codable {
    let customerName: String
    let customerGuid: String?
    let linkMan: String?
    let salesGuid: String?
    let salesName: String?
    let salesGroupGuid: String?
    let source: String?
    let materialNo: String?
    let materialName: String?
    let materialGuid: String?
    let materialTypeName: String?
    let weaveType: String?
    let width: Double?
    let beamTotalEnd: Int?
    let warpDensity: Double?
    let weftDensity: Double?
    let warpWastagePercent: Double?
    let reedId: Double?
    let fastenerRange: Double?
    let reedType: String?
    let sideLength: Double?
    let weaveSpeed: Double?
    let weaveEff: Double?
    let weaveDayOutput: Double?
    let weaveDayCost: Double?
    let weaveDaySaleCost: Double?
    let price: Double?
    let costPrice: Double?
    let weavePrice: Double?
    let sizingPrice: Double?
    let sandingPrice: Double?
    let stdWeavePrice: Double?
    let sampleCost: Double?
    let orderQty: Double?
    let orderType: String?
    let balanceType: String?
    let currency: String?
    let deliveryDate: String?
    let profitRate: Double?
    let sizingProviderName: String?
    let sizingProviderGuid: String?
    let remark: String?
    let creator: String
    let materials: [QuoteCreateMaterialRow]
    let finishDetails: [QuoteCreateFinishRow]
}

struct QuoteCreateResponse: Codable {
    let quoteNo: String
    let guid: String
}

// MARK: - BOM (Bill of Materials)

struct BOMResponse: Codable {
    let yarns: [BOMYarn]
}

struct BOMYarn: Codable, Identifiable {
    let usage: String
    let label: String?
    let materialNo: String?
    let materialName: String?
    let materialGuid: String?
    let denierNum: Double?
    let yarnCount: String?
    let patternPerQty: Int?
    let patternTotalQty: Int?
    let percent: Double?
    let suggestedSupplier: BOMSupplier?

    var id: String {
        "\(usage)-\(label ?? "")-\(materialNo ?? "")"
    }

    var usageDisplayName: String {
        usage == "J" ? "经纱" : "纬纱"
    }
}

struct BOMSupplier: Codable {
    let code: String
    let name: String
}

// MARK: - Weave Pattern

struct WeavePatternResponse: Codable {
    let quoteNo: String
    let materialName: String?
    let weaveStructure: WeaveGrid?
    let groundStructure: WeaveGrid?
    let backStructure: WeaveGrid?
    let warpPattern: String?
    let weftPattern: String?
    let reedDraft: String?
    let meta: WeaveMeta?
}

struct WeaveGrid: Codable {
    let width: Int
    let height: Int
    let grid: [[Int]]
}

struct WeaveMeta: Codable {
    let artNo: String?
    let reedId: Double?
    let reedType: String?
    let heddleFrames: String?
    let weaveSpeed: Int?
    let weaveEfficiency: Double?
    let dayOutput: Double?
    let weftDensity: String?
    let artType: String?
    let patternCategory: String?
}
