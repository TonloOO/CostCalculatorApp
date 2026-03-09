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
        case .editing: return "编辑"
        case .submitted: return "提交"
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
        case "编辑": self = .editing
        case "提交": self = .submitted
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
    let beamTotalEnd: Int?
    let width: Double?
    let orderQty: Double?
    let weftDensity: Double?
    let weaveDaySaleCost: Double?
    let price: Double?
    let weaveDayOutput: Double?
    let quoteTime: String?
    let materials: [QuoteMaterial]?
    
    var id: String { quoteNo }
}

struct QuoteMaterial: Codable, Identifiable {
    let materialName: String?
    let providerName: String?
    let unitPrice: Double?
    
    var id: String { "\(materialName ?? "")-\(providerName ?? "")-\(unitPrice ?? 0)" }
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
        if orderSyncTriggered {
            return "\(quoteNo) 已从\(previousStatus)变更为\(currentStatus)，并已触发订单同步"
        }

        return "\(quoteNo) 已从\(previousStatus)变更为\(currentStatus)"
    }
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
