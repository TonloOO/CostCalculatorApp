//
//  CostCalculatorAppTests.swift
//  CostCalculatorAppTests
//
//  Created by Zishuo Li on 2024-09-24.
//

import Foundation
import Testing
@testable import CostCalculatorApp

struct CostCalculatorAppTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func weavePatternDecodingSupportsRepeatGroupsAndColorAssignments() throws {
        let json = """
        {
          "quoteNo": "Q-001",
          "materialName": "测试布种",
          "weaveStructure": {
            "width": 4,
            "height": 4,
            "grid": [
              [1, 2, 3, 4],
              [2, 2, 3, 4],
              [3, 2, 3, 4],
              [4, 2, 3, 4]
            ],
            "repeatGroups": [
              { "startRow": 0, "endRow": 1, "repeat": 2 },
              { "startRow": 2, "endRow": 3, "repeat": 4 }
            ],
            "colorAssignments": [
              { "groupIndex": 0, "color": "B" },
              { "groupIndex": 1, "color": "A" }
            ]
          },
          "groundStructure": null,
          "backStructure": null,
          "warpPattern": "AABB",
          "weftPattern": "BBAA",
          "reedDraft": "1,2,3,4",
          "meta": {
            "artNo": "ART-1",
            "reedId": 88.0,
            "reedType": "2入",
            "heddleFrames": "1,2,3,4",
            "weaveSpeed": 500,
            "weaveEfficiency": 92.5,
            "dayOutput": 123.4,
            "weftDensity": "68",
            "artType": "提花",
            "patternCategory": "大提花"
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(WeavePatternResponse.self, from: json)

        #expect(decoded.weaveStructure?.repeatGroups.count == 2)
        #expect(decoded.weaveStructure?.repeatGroups.first?.startRow == 0)
        #expect(decoded.weaveStructure?.repeatGroups.last?.repeat == 4)
        #expect(decoded.weaveStructure?.colorAssignments.count == 2)
        #expect(decoded.weaveStructure?.colorAssignments.first?.color == "B")
        #expect(decoded.weaveStructure?.colorAssignments.last?.groupIndex == 1)
    }

    @Test func weaveGridDisplayRowsReverseVerticalOrderAndKeepLabelsAligned() {
        let grid = WeaveGrid(
            width: 4,
            height: 4,
            grid: [
                [1, 2, 3, 4],
                [2, 2, 3, 4],
                [3, 2, 3, 4],
                [4, 2, 3, 4]
            ],
            repeatGroups: [],
            colorAssignments: []
        )

        #expect(grid.displayRows.map(\.displayRowNumber) == [4, 3, 2, 1])
        #expect(grid.displayRows.map(\.sourceRowIndex) == [3, 2, 1, 0])
        #expect(grid.displayRows.first?.cells == [4, 2, 3, 4])
        #expect(grid.displayRows.last?.cells == [1, 2, 3, 4])
    }

    @Test func weaveGridCompactERPLayoutUsesBaseRowsAndExtraGuideColumns() {
        let grid = WeaveGrid(
            width: 2,
            height: 8,
            grid: [
                [1, 0],
                [0, 1],
                [1, 1],
                [0, 0],
                [1, 0],
                [0, 1],
                [1, 1],
                [0, 0]
            ],
            repeatGroups: [
                WeaveRepeatGroup(startRow: 0, endRow: 1, repeat: 2),
                WeaveRepeatGroup(startRow: 2, endRow: 3, repeat: 4),
                WeaveRepeatGroup(startRow: 4, endRow: 5, repeat: 2),
                WeaveRepeatGroup(startRow: 6, endRow: 7, repeat: 4)
            ],
            colorAssignments: [
                WeaveColorAssignment(groupIndex: 0, color: "B"),
                WeaveColorAssignment(groupIndex: 1, color: "A"),
                WeaveColorAssignment(groupIndex: 2, color: "B"),
                WeaveColorAssignment(groupIndex: 3, color: "A")
            ]
        )

        let compact = grid.compactERPLayout

        #expect(compact?.width == 4)
        #expect(compact?.height == 4)
        #expect(compact?.grid[0] == [1, 0, 0, 0])
        #expect(compact?.grid[3] == [0, 0, 0, 0])
        #expect(compact?.sections.count == 2)
        #expect(compact?.sections.first?.repeat == 2)
        #expect(compact?.sections.last?.repeat == 4)
        #expect(compact?.sections.last?.cumulativeEndsAt == 12)
    }

}
