# UI Optimization Design — CostCalculatorApp

**Date:** 2026-03-25
**Scope:** Visual refinement only — no functional changes
**Target:** iOS 18.0+

---

## Background

The app serves Chinese-speaking textile industry professionals. The current UI uses a multi-colored gradient card system (`cardGradient1`–`cardGradient4`) that feels consumer-facing rather than professional. The goal is to shift toward a more restrained, business-appropriate aesthetic while preserving brand identity.

**Design direction:** Restrained + business-like. Reduce gradient surface area. Replace multi-color card gradients with a single brand-color header banner and white content cards.

---

## 1. Header Banner (Tab Root Views Only)

**Affected files:** `HomeView.swift`, `StatisticHomeView.swift`, `ChatView.swift`, `ProfileView.swift`

These are the four tab root views in `ContentView`. `CalculationHomeView` is a sub-page pushed onto the `NavigationStack` from `HomeView` — it does **not** receive a banner. It adopts the system navigation bar instead (see Section 4).

**Change:** Replace the current plain `largeTitle` + `groupedBackground` header pattern with a brand-color gradient banner at the top of each tab root view.

**Banner spec:**
- Background: `primaryGradient` (`#5B67CA → #7B85E0`, top-leading to bottom-trailing), extends into the safe area top inset
- Content area height: 80pt (below safe area inset) — total visual height will vary by device safe area
- Content: small category label (11pt, white 70% opacity) + large title (22pt, bold, white) + subtitle (13pt, white 75% opacity)
- Decorative: two overlapping semi-transparent white circles (opacity 7%) positioned top-right for depth
- Bottom: rounded corners (12pt radius) overlapping the content area below by 12pt, creating a card-lift effect

**StatisticHomeView banner addition:** Embed quick-stat chips (e.g. "总计算 42 次", "今日 3 次") inside the banner using `background: rgba(white, 0.18)` capsule pills. These values are computed properties already available on `StatisticHomeView` (`records.count`, `todayRecordsCount`) — pass them as parameters to the banner subview rather than re-fetching.

**ChatView note:** `ChatView` has no `NavigationView`/`NavigationStack` and uses a hand-rolled `headerBar` private view. Add the banner directly at the top of the root `VStack`, replacing the existing `headerBar`. Wrap the content in a `NavigationStack` so sub-pages (e.g. image picker) can push onto the stack.

---

## 2. Card Redesign

### 2a. HomeView — ModuleCard

**Affected file:** `HomeView.swift`

**Change:** Replace the current `ModuleCard` (full-gradient background, tall fixed height, feature pill tags) with a white list-style card using the new `AppListCard` component (see 2b).

### 2b. Consolidated AppListCard

**Affected file:** `CustomComponents.swift`

`FeatureCard` (used in `CalculationHomeView`) and `ModuleCard` (used in `HomeView`) serve the same navigational purpose with different visual treatments. Unify them into a single reusable component:

```swift
struct AppListCard: View {
    let title: String
    let subtitle: String
    let icon: String
}
```

`AppListCard` is a **passive display component** — it has no action parameter. All tap handling is done by the caller via `NavigationLink` or `Button` wrapping the card, matching the existing pattern at call sites.

**Visual spec:**
- Background: white, corner radius 12pt, shadow `(black 6% opacity, radius 4, y 1)`
- Layout: horizontal — icon container (48×48pt, corner radius 12pt, background `AppTheme.Colors.primary.opacity(0.1)`) + text block (title 15pt semibold + subtitle 12pt `secondaryText`) + chevron `›` (16pt, `Color.gray.opacity(0.4)`)
- Use `.clipShape(RoundedRectangle(cornerRadius: 12))` instead of deprecated `.cornerRadius(12)`
- Icon: `Image(systemName: icon)` colored `AppTheme.Colors.primary` — single brand color, no per-card color theming

### 2c. StatisticHomeView — StatisticRow grouping

**Affected file:** `StatisticHomeView.swift`

**Change:** `StatisticRow` already uses a white card pattern — keep its internal layout. Remove the individual shadow per row and instead wrap each logical group (月度统计, 材料使用统计, 成本构成) in a single rounded container:
- Outer container: white background, corner radius 12pt, single shadow `(black 6% opacity, radius 4, y 1)`
- Inner rows: no individual shadow, separated by 1pt `Color(UIColor.separator)` dividers
- This reduces visual noise from stacked shadows

---

## 3. Tab Bar Refinement

**Affected file:** `CustomComponents.swift` — `CustomTabBar` and `TabBarItem`

**Changes:**
- Icon font size: 24pt → 20pt
- Label font: replace `AppTheme.Typography.caption2` with new `AppTheme.Typography.tabLabel`. Add `static let tabLabel = Font.system(size: 10, weight: .regular, design: .default)` to `Theme.swift`. Note: `caption2` is 11pt — `tabLabel` at 10pt is intentionally 1pt smaller to achieve the slimmer look; do not reuse `caption2`
- Icon–label gap: 4pt → 3pt
- Top padding: 12pt → 8pt
- Bottom padding: unchanged (safe area driven)

No structural changes to tab bar logic or selection behavior.

---

## 4. Navigation Unification

**Affected files:** `StatisticHomeView.swift`, `CalculationHomeView.swift`, `HistoryView.swift`, `CustomComponents.swift`, `ProfileView.swift`, `ChatView.swift`

### Remove legacy navigation

| Location | Current | Action |
|---|---|---|
| `StatisticHomeView` root | `NavigationView` + `.navigationBarHidden(true)` | Replace outer `NavigationView` with `NavigationStack`; hide nav bar with `.toolbar(.hidden, for: .navigationBar)` |
| `ProfileView` root | `NavigationStack` + `.navigationBarHidden(true)` | Replace `.navigationBarHidden(true)` with `.toolbar(.hidden, for: .navigationBar)` |
| `ProfileView` sheet sub-views | `AISettingsView`, `AppSettingsView`, `AboutView`, `CloudKitSettingsView`, `LanguageSettingsView`, `ModelPickerSheet` each embed `NavigationView` internally | Migrate each to `NavigationStack`. These already use correct `.navigationTitle` / `.toolbar` API internally; only the outer wrapper changes |
| `CalculationHomeView` sheet | `NavigationView` + `.navigationBarItems(trailing:)` | Replace with `NavigationStack` + `.toolbar { ToolbarItem(placement: .topBarTrailing) { … } }` |
| `HistoryView` sheet | `NavigationView` + `.navigationBarItems(trailing:)` inside `recordToEdit` sheet | Replace with `NavigationStack` + `ToolbarItem` |
| `ChatView` internal sheet | `NavigationView` + `.navigationBarItems(trailing:)` inside `showCalculator` sheet | Replace with `NavigationStack` + `ToolbarItem` |
| `CustomNavigationBar` struct | Unused struct in `CustomComponents.swift` | Remove (no call sites — grep confirms zero matches for `CustomNavigationBar`) |

### Sub-page navigation pattern

Sub-pages in scope that use `customNavHeader()` (`CalculationHomeView`, `HistoryView`) should be migrated to the system nav bar:
- Remove `customNavHeader()` calls and `.toolbar(.hidden, for: .navigationBar)`
- Adopt: `.navigationTitle("页面标题")` + `.navigationBarTitleDisplayMode(.inline)`
- Back button is provided automatically by `NavigationStack`

**Important:** `CostCalculatorView` and `CostCalculatorViewWithMaterial` also call `customNavHeader()` but are **out of scope** (no changes to input form layout). Do **not** delete the `customNavHeader()` function in Step 8 until those views are migrated in a future pass. Step 8 should only remove `FeatureCard`, `ModuleCard`, and `CustomNavigationBar`.

`QuoteHomeView` also calls `customNavHeader()` and is out of scope — leave untouched.

---

## 5. Opportunistic Cleanup (while touching files)

These are not primary goals but should be fixed when a file is already being edited:

- Replace `.cornerRadius()` (deprecated) with `.clipShape(RoundedRectangle(cornerRadius:))` in any modified view
- Replace hard-coded `.padding(.bottom, 100)` with `AppTheme.Spacing.tabBarClearance: CGFloat = 88` in all in-scope views (`HomeView`, `StatisticHomeView`, `CalculationHomeView`, `ProfileView`). The 88pt value is derived from: CustomTabBar visual height ~50pt + bottom safe area inset ~34pt + 4pt margin = 88pt (deliberately smaller than the over-padded 100pt). `QuoteOverviewView` and `QuoteLoginView` also use `.padding(.bottom, 100)` but are out of scope — leave them with the hard-coded value
- Remove `GlassMorphismStyle`, `VisualEffectBlur`, and the `.glassMorphism()` extension from `ViewModifiers.swift`. First grep for `.glassMorphism(` across the project — if zero matches, delete all three. If any matches found, leave them and note in the PR

---

## Implementation Order (Approach 2 — Visual First)

1. **`Theme.swift`** — add `AppTheme.Typography.tabLabel` (10pt) and `AppTheme.Spacing.tabBarClearance` (88pt)
2. **`CustomComponents.swift`** — create `AppListCard`, slim `TabBarItem` (use new `tabLabel` font), remove `CustomNavigationBar` struct
3. **`HomeView.swift`** — add banner, replace `ModuleCard` with `AppListCard`
4. **`CalculationHomeView.swift`** — replace `FeatureCard` with `AppListCard`, fix sheet navigation, adopt system nav bar (remove `customNavHeader`)
5. **`StatisticHomeView.swift`** — add banner with stat chips (pass `records.count` and `todayRecordsCount` as parameters), replace `NavigationView`, group `StatisticRow` containers
6. **`ProfileView.swift`** — add banner, fix `.navigationBarHidden` → `.toolbar(.hidden, for: .navigationBar)`
7. **`ChatView.swift`** — add banner replacing `headerBar`, wrap content in `NavigationStack`
8. **`CustomComponents.swift`** (second pass) — remove `FeatureCard` and `ModuleCard` (do **not** remove `customNavHeader()` — it is still used by out-of-scope views)
9. **`ViewModifiers.swift`** — remove `GlassMorphismStyle`, `VisualEffectBlur`, `.glassMorphism()` after confirming no grep matches for `.glassMorphism(`

---

## Out of Scope

- No changes to calculation logic, data models, or API integrations
- No changes to `CostCalculatorView` or `CostCalculatorViewWithMaterial` input form layout
- No new features or screens
- No color scheme changes beyond banner adoption (dark mode support inherited from existing `AppTheme.Colors` semantic colors)
