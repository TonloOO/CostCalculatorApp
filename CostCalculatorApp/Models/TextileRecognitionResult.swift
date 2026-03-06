import Foundation

struct RecognizedMaterial: Codable {
    var name: String?
    var warpYarnType: String?
    var warpYarnValue: String?
    var weftYarnType: String?
    var weftYarnValue: String?
    var warpYarnPrice: String?
    var weftYarnPrice: String?
    var warpRatio: String?
    var weftRatio: String?
}

struct TextileRecognitionResult: Codable {
    var customerName: String?
    var boxNumber: String?
    var threading: String?
    var fabricWidth: String?
    var edgeFinishing: String?
    var fabricShrinkage: String?
    var weftDensity: String?
    var machineSpeed: String?
    var efficiency: String?
    var dailyLaborCost: String?
    var fixedCost: String?
    var materials: [RecognizedMaterial]
    var confidence: String?
    var notes: String?

    var isSingleMaterial: Bool {
        materials.count <= 1
    }

    var summaryText: String {
        var lines: [String] = []
        if let box = boxNumber { lines.append("筘号: \(box)") }
        if let width = fabricWidth { lines.append("门幅: \(width) cm") }
        if let density = weftDensity { lines.append("纬密: \(density)") }
        if let thread = threading { lines.append("穿综: \(thread)") }
        for (i, m) in materials.enumerated() {
            let label = m.name ?? "材料\(i + 1)"
            var parts: [String] = []
            if let wv = m.warpYarnValue, let wt = m.warpYarnType {
                parts.append("经纱 \(wv) \(wt)")
            }
            if let fv = m.weftYarnValue, let ft = m.weftYarnType {
                parts.append("纬纱 \(fv) \(ft)")
            }
            if !parts.isEmpty {
                lines.append("\(label): \(parts.joined(separator: ", "))")
            }
        }
        return lines.isEmpty ? "未识别到有效数据" : lines.joined(separator: "\n")
    }
}
