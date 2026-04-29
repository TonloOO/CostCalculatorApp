//
//  MachineListView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-04-29.
//

import SwiftUI

struct MachineListView: View {
    /// nil means "all" — show every bucket together.
    let initialBucket: MachineBucket?

    @State private var apiService = MachineAPIService.shared
    @State private var items: [MachineListItem] = []
    @State private var bucketFilter: MachineBucket?
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(initialBucket: MachineBucket? = nil) {
        self.initialBucket = initialBucket
        self._bucketFilter = State(initialValue: initialBucket)
    }

    var body: some View {
        List {
            if items.isEmpty && isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            } else if items.isEmpty, let errorMessage {
                Section {
                    ContentUnavailableView {
                        Label("加载失败", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("重试") {
                            Task { await load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                }
            } else if items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "暂无机台",
                        systemImage: "tray",
                        description: Text("当前筛选下没有机台")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            MachineDetailView(equipmentNo: item.equipmentNo)
                        } label: {
                            MachineRow(item: item)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        bucketFilter = nil
                        Task { await load() }
                    } label: {
                        Label("全部", systemImage: bucketFilter == nil ? "checkmark" : "")
                    }
                    Divider()
                    ForEach(MachineBucket.allCases, id: \.self) { bucket in
                        Button {
                            bucketFilter = bucket
                            Task { await load() }
                        } label: {
                            Label(
                                bucket.displayName,
                                systemImage: bucketFilter == bucket ? "checkmark" : ""
                            )
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable {
            await load()
        }
        .task {
            if items.isEmpty { await load() }
        }
    }

    private var navigationTitle: String {
        bucketFilter?.displayName ?? "全部机台"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await apiService.fetchList(bucket: bucketFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Row

private struct MachineRow: View {
    let item: MachineListItem

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(item.bucketEnum.color)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Text(item.equipmentNo)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    if let name = item.equipmentName, !name.isEmpty {
                        Text(name)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }

                if let location = item.location, !location.isEmpty {
                    Text(location)
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(relativeTime(item.lastTrackTime))
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                if item.length24h > 0 {
                    Text(String(format: "24h: %.0f 米", item.length24h))
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func relativeTime(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "未上报" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let isoString = raw.contains("T") ? raw : raw.replacingOccurrences(of: " ", with: "T")
        guard let date = formatter.date(from: isoString) ?? parseLocal(raw) else {
            return raw
        }

        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "刚刚" }
        if interval < 3_600 { return "\(Int(interval / 60)) 分钟前" }
        if interval < 86_400 { return "\(Int(interval / 3_600)) 小时前" }
        return "\(Int(interval / 86_400)) 天前"
    }

    private func parseLocal(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.date(from: raw)
    }
}

#Preview {
    NavigationStack {
        MachineListView(initialBucket: .activeToday)
    }
}
