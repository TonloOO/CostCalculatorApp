//
//  MachineModels.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-04-29.
//

import Foundation
import SwiftUI

// MARK: - Bucket

enum MachineBucket: String, Codable, CaseIterable, Hashable {
    case activeToday    = "active_today"
    case idleYesterday  = "idle_yesterday"
    case idle2to7d      = "idle_2_7d"
    case idleGt7d       = "idle_gt_7d"
    case neverReported  = "never_reported"

    var displayName: String {
        switch self {
        case .activeToday:    return "今日活跃"
        case .idleYesterday:  return "昨日活跃"
        case .idle2to7d:      return "2-7 天闲置"
        case .idleGt7d:       return "7 天以上"
        case .neverReported:  return "从未上报"
        }
    }

    var color: Color {
        switch self {
        case .activeToday:    return .green
        case .idleYesterday:  return .yellow
        case .idle2to7d:      return .orange
        case .idleGt7d:       return .red
        case .neverReported:  return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .activeToday:    return "circle.fill"
        case .idleYesterday:  return "circle.fill"
        case .idle2to7d:      return "circle.fill"
        case .idleGt7d:       return "exclamationmark.circle.fill"
        case .neverReported:  return "questionmark.circle.fill"
        }
    }
}

// MARK: - Overview

struct MachineDailyTrend: Codable, Hashable, Identifiable {
    let date: String
    let activeMachines: Int
    let totalLength: Double
    let recordCount: Int

    var id: String { date }
}

struct MachineTodaySummary: Codable, Hashable {
    let active: Int
    let totalLength: Double
    let recordCount: Int
}

struct MachineBucketCounts: Codable, Hashable {
    let active_today: Int
    let idle_yesterday: Int
    let idle_2_7d: Int
    let idle_gt_7d: Int
    let never_reported: Int

    func count(for bucket: MachineBucket) -> Int {
        switch bucket {
        case .activeToday:    return active_today
        case .idleYesterday:  return idle_yesterday
        case .idle2to7d:      return idle_2_7d
        case .idleGt7d:       return idle_gt_7d
        case .neverReported:  return never_reported
        }
    }
}

struct MachineOverview: Codable, Hashable {
    let serverTime: String
    let today: MachineTodaySummary
    let trend: [MachineDailyTrend]
    let bucketCounts: MachineBucketCounts
}

// MARK: - List

struct MachineListItem: Codable, Hashable, Identifiable {
    let equipmentNo: String
    let equipmentName: String?
    let location: String?
    let lastTrackTime: String?
    let bucket: String
    let length24h: Double
    let length7d: Double
    let recordCount24h: Int

    var id: String { equipmentNo }

    var bucketEnum: MachineBucket {
        MachineBucket(rawValue: bucket) ?? .neverReported
    }
}

// MARK: - Detail

struct MachineDailySummary: Codable, Hashable, Identifiable {
    let date: String
    let totalLength: Double
    let recordCount: Int
    let workerGroups: [String]

    var id: String { date }
}

struct MachineRecord: Codable, Hashable, Identifiable {
    let trackTime: String
    let fabricNo: String?
    let length: Double?
    let workerNo: String?
    let workerGroup: String?
    let weaveFlag: String?

    var id: String { trackTime + (fabricNo ?? "") }
}

struct MachineDetail: Codable, Hashable {
    let equipmentNo: String
    let equipmentName: String?
    let location: String?
    let bucket: String
    let lastTrackTime: String?
    let dailySummary: [MachineDailySummary]
    let recentRecords: [MachineRecord]

    var bucketEnum: MachineBucket {
        MachineBucket(rawValue: bucket) ?? .neverReported
    }
}
