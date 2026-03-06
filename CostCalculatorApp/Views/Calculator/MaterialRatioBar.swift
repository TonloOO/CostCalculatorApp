//
//  MaterialRatioBar.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2025-03-04.
//

import SwiftUI

struct MaterialColors {
    static let palette: [Color] = [
        Color(hex: "5B67CA"),
        Color(hex: "FF6B6B"),
        Color(hex: "43E97B"),
        Color(hex: "FFC107"),
        Color(hex: "4FACFE"),
        Color(hex: "F093FB"),
        Color(hex: "FF9A76"),
        Color(hex: "6BCB77"),
    ]
    
    static func color(for index: Int) -> Color {
        palette[index % palette.count]
    }
}

// MARK: - Display mode
enum RatioBarMode {
    case ratio
    case cost
}

// MARK: - Result-based ratio bar (read-only, for CalculationDetailView)
struct MaterialRatioBar: View {
    let results: [MaterialCalculationResult]
    var mode: RatioBarMode = .ratio
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if mode == .ratio {
                ratioView
            } else {
                costView
            }
            
            legendView
        }
    }
    
    @ViewBuilder
    private var ratioView: some View {
        let warpSegments = results.enumerated().compactMap { (i, r) -> BarSegment? in
            let val = Double(r.material.warpRatio ?? "0") ?? 0
            guard val > 0 else { return nil }
            return BarSegment(label: r.material.name, value: val, color: MaterialColors.color(for: i))
        }
        let weftSegments = results.enumerated().compactMap { (i, r) -> BarSegment? in
            let val = Double(r.material.weftRatio ?? "0") ?? 0
            guard val > 0 else { return nil }
            return BarSegment(label: r.material.name, value: val, color: MaterialColors.color(for: i))
        }
        
        if !warpSegments.isEmpty {
            StackedBar(title: "经纱占比", segments: warpSegments)
        }
        if !weftSegments.isEmpty {
            StackedBar(title: "纬纱占比", segments: weftSegments)
        }
    }
    
    @ViewBuilder
    private var costView: some View {
        let warpSegments = results.enumerated().compactMap { (i, r) -> BarSegment? in
            guard r.warpCost > 0 else { return nil }
            return BarSegment(label: r.material.name, value: r.warpCost, color: MaterialColors.color(for: i))
        }
        let weftSegments = results.enumerated().compactMap { (i, r) -> BarSegment? in
            guard r.weftCost > 0 else { return nil }
            return BarSegment(label: r.material.name, value: r.weftCost, color: MaterialColors.color(for: i))
        }
        
        if !warpSegments.isEmpty {
            StackedBar(title: "经纱成本", segments: warpSegments)
        }
        if !weftSegments.isEmpty {
            StackedBar(title: "纬纱成本", segments: weftSegments)
        }
    }
    
    private var legendView: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            ForEach(Array(results.enumerated()), id: \.offset) { i, result in
                HStack(spacing: 4) {
                    Circle()
                        .fill(MaterialColors.color(for: i))
                        .frame(width: 8, height: 8)
                    Text(result.material.name)
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Live ratio bar (for input section, reads from [Material] binding)
struct LiveMaterialRatioBar: View {
    let materials: [Material]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            let warpSegments = materials.enumerated().compactMap { (i, m) -> BarSegment? in
                let val = Double(m.warpRatio ?? "0") ?? 0
                guard val > 0 else { return nil }
                return BarSegment(label: m.name, value: val, color: MaterialColors.color(for: i))
            }
            let weftSegments = materials.enumerated().compactMap { (i, m) -> BarSegment? in
                let val = Double(m.weftRatio ?? "0") ?? 0
                guard val > 0 else { return nil }
                return BarSegment(label: m.name, value: val, color: MaterialColors.color(for: i))
            }
            
            if !warpSegments.isEmpty {
                StackedBar(title: "经纱占比", segments: warpSegments)
            }
            if !weftSegments.isEmpty {
                StackedBar(title: "纬纱占比", segments: weftSegments)
            }
            
            if !warpSegments.isEmpty || !weftSegments.isEmpty {
                legendFromMaterials
            }
        }
    }
    
    private var legendFromMaterials: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            ForEach(Array(materials.enumerated()), id: \.offset) { i, material in
                HStack(spacing: 4) {
                    Circle()
                        .fill(MaterialColors.color(for: i))
                        .frame(width: 8, height: 8)
                    Text(material.name)
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Ratio Slider Input Field
struct RatioSliderField: View {
    let label: String
    @Binding var ratio: String
    
    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(ratio) ?? 0 },
            set: { ratio = $0 > 0 ? String(format: "%.1f", $0) : "" }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            HStack(spacing: 12) {
                Slider(value: sliderValue, in: 0...10, step: 0.1)
                    .tint(AppTheme.Colors.primary)
                
                TextField("0", text: $ratio)
                    .keyboardType(.decimalPad)
                    .font(AppTheme.Typography.body)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.Colors.tertiaryBackground)
                    )
            }
        }
    }
}

// MARK: - Shared components

struct BarSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct StackedBar: View {
    let title: String
    let segments: [BarSegment]
    
    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(segments) { segment in
                        let fraction = total > 0 ? segment.value / total : 0
                        let pct = Int(fraction * 100)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segment.color)
                            .frame(width: max(fraction * (geo.size.width - CGFloat(segments.count - 1)), 0))
                            .overlay {
                                if fraction >= 0.15 {
                                    Text("\(pct)%")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
