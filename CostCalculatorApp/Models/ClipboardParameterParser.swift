//
//  ClipboardParameterParser.swift
//  CostCalculatorApp
//
//  Pure parsing utility for extracting textile parameters from
//  clipboard text. Extracted from CostCalculatorView for reuse and testability.
//

import Foundation

enum ClipboardParameterParser {

    /// Canonical parameter names mapped to all known synonyms / variants found in the wild.
    static let parameterSynonyms: [String: [String]] = [
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

    /// True if the text likely contains any recognised parameter keyword.
    static func containsParameters(in content: String) -> Bool {
        for (_, synonyms) in parameterSynonyms {
            for synonym in synonyms where content.contains(synonym) {
                return true
            }
        }
        return false
    }

    /// Extracts a `{canonicalName: rawValue}` map from arbitrary input text.
    static func extractParameters(from text: String) -> [String: String] {
        var extractedParameters: [String: String] = [:]

        let cleanedText = text.replacing(" ", with: "")
        let components = cleanedText.components(separatedBy: CharacterSet(charactersIn: ",;，；"))

        for component in components {
            for (parameterKey, synonyms) in parameterSynonyms {
                for synonym in synonyms where component.contains(synonym) {
                    if let value = extractValue(after: synonym, in: component) {
                        extractedParameters[parameterKey] = value
                        break
                    }
                }
            }
        }

        return extractedParameters
    }

    /// Pulls the value substring that follows a keyword, stopping at the next
    /// known synonym or the end of the component.
    private static func extractValue(after keyword: String, in text: String) -> String? {
        guard let keywordRange = text.range(of: keyword) else { return nil }

        var valueStartIndex = keywordRange.upperBound

        let possibleSeparators = [":", "：", "=", "-"]
        if valueStartIndex < text.endIndex {
            let nextChar = text[valueStartIndex]
            if possibleSeparators.contains(String(nextChar)) {
                valueStartIndex = text.index(after: valueStartIndex)
            }
        }

        let remainingText = text[valueStartIndex...]

        var valueEndIndex = text.endIndex
        for (_, synonyms) in parameterSynonyms {
            for synonym in synonyms {
                if let range = remainingText.range(of: synonym),
                   range.lowerBound != remainingText.startIndex {
                    valueEndIndex = text.index(
                        valueStartIndex,
                        offsetBy: range.lowerBound.utf16Offset(in: remainingText)
                    )
                    break
                }
            }
        }

        let valueRange = valueStartIndex..<valueEndIndex
        return String(text[valueRange]).trimmingCharacters(in: CharacterSet(charactersIn: ":：=-"))
    }
}
