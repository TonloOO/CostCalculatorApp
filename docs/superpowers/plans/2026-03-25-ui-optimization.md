# UI Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace multi-color gradient cards and inconsistent navigation with a single brand-color banner header and white list-style cards across all screens.

**Architecture:** Visual-only pass — no logic, data model, or API changes. Each task is independently buildable. The new `AppListCard` component replaces both `FeatureCard` and `ModuleCard`. All tab root views get a `BannerHeader` subview. Navigation is unified to `NavigationStack` throughout.

**Tech Stack:** SwiftUI, iOS 18, Core Data, Xcode — no new dependencies.

---

## File Map

| File | Change |
|---|---|
| `Theme/Theme.swift` | Add `Typography.tabLabel` (10pt) and `Spacing.tabBarClearance` (88pt) |
| `Components/CustomComponents.swift` | Add `AppListCard`; slim `TabBarItem`; remove `CustomNavigationBar`, `FeatureCard` |
| `Views/HomeView.swift` | Add `BannerHeader`; replace `ModuleCard` with `AppListCard`; replace `.padding(.bottom, 100)` |
| `Views/Calculator/CalculationHomeView.swift` | Replace `FeatureCard` with `AppListCard`; remove `customNavHeader`; adopt system nav bar; fix sheet `NavigationView` |
| `Views/Statistic/StatisticHomeView.swift` | Add `BannerHeader` with stat chips; replace `NavigationView`; group `StatisticRow` in containers |
| `Views/Settings/ProfileView.swift` | Add `BannerHeader`; fix `.navigationBarHidden`; migrate 6 sheet sub-views to `NavigationStack` |
| `Views/Chat/ChatView.swift` | Replace `headerBar` with `BannerHeader`; wrap calculator sheet in `NavigationStack` |
| `Views/Calculator/HistoryView.swift` | Fix `recordToEdit` sheet `NavigationView` → `NavigationStack` |
| `Theme/ViewModifiers.swift` | Remove `GlassMorphismStyle`, `VisualEffectBlur`, `.glassMorphism()` extension |

**Build command** (run after each task to verify no regressions):
```bash
cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
xcodebuild -project CostCalculatorApp.xcodeproj \
  -scheme CostCalculatorApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

---

## Task 1: Add Theme Constants

**Files:**
- Modify: `CostCalculatorApp/Theme/Theme.swift`

- [ ] **Step 1: Add `tabLabel` to `AppTheme.Typography`**

  In `Theme.swift`, add after the `caption2` line (line 88):
  ```swift
  static let tabLabel = Font.system(size: 10, weight: .regular, design: .default)
  ```
  Note: `caption2` is 11pt — `tabLabel` is intentionally 1pt smaller for the slimmed tab bar.

- [ ] **Step 2: Add `tabBarClearance` to `AppTheme.Spacing`**

  In `Theme.swift`, add after `xxxLarge` (line 104):
  ```swift
  static let tabBarClearance: CGFloat = 88  // tab bar ~50pt + safe area ~34pt + 4pt margin
  ```

- [ ] **Step 3: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Theme/Theme.swift && \
  git commit -m "feat: add tabLabel and tabBarClearance theme constants"
  ```

---

## Task 2: AppListCard + TabBarItem Slim + Remove CustomNavigationBar

**Files:**
- Modify: `CostCalculatorApp/Components/CustomComponents.swift`

- [ ] **Step 1: Add `AppListCard` to `CustomComponents.swift`**

  Add after the `SectionHeader` struct (around line 329):
  ```swift
  // MARK: - App List Card

  /// Passive display card for navigable list items.
  /// Always wrap in NavigationLink or Button — this view handles no actions itself.
  struct AppListCard: View {
      let title: String
      let subtitle: String
      let icon: String

      var body: some View {
          HStack(spacing: AppTheme.Spacing.medium) {
              ZStack {
                  RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 4)
                      .fill(AppTheme.Colors.primary.opacity(0.1))
                      .frame(width: 48, height: 48)
                  Image(systemName: icon)
                      .font(.system(size: 22, weight: .medium))
                      .foregroundColor(AppTheme.Colors.primary)
              }

              VStack(alignment: .leading, spacing: 3) {
                  Text(title)
                      .font(AppTheme.Typography.headline)
                      .foregroundColor(AppTheme.Colors.primaryText)
                  Text(subtitle)
                      .font(AppTheme.Typography.footnote)
                      .foregroundColor(AppTheme.Colors.secondaryText)
              }

              Spacer()

              Image(systemName: "chevron.right")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(AppTheme.Colors.tertiaryText)
          }
          .padding(AppTheme.Spacing.medium)
          .background(AppTheme.Colors.background)
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
          .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
      }
  }
  ```

- [ ] **Step 2: Slim down `TabBarItem`**

  In `TabBarItem.body`, make these three changes:
  1. Icon font: `.font(.system(size: 24))` → `.font(.system(size: 20))`
  2. Label font: `.font(AppTheme.Typography.caption2)` → `.font(AppTheme.Typography.tabLabel)`
  3. VStack spacing: `spacing: 4` → `spacing: 3`

  In `CustomTabBar.body`, change top padding:
  - `.padding(.vertical, AppTheme.Spacing.xSmall)` → `.padding(.top, 8).padding(.bottom, AppTheme.Spacing.xSmall)`

- [ ] **Step 3: Remove `CustomNavigationBar` struct**

  Delete the entire `CustomNavigationBar` struct (lines 11–48). No call sites exist (confirmed by grep).

- [ ] **Step 4: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Components/CustomComponents.swift && \
  git commit -m "feat: add AppListCard, slim TabBarItem, remove CustomNavigationBar"
  ```

---

## Task 3: HomeView — Banner + AppListCard

**Files:**
- Modify: `CostCalculatorApp/Views/HomeView.swift`

- [ ] **Step 1: Add `BannerHeader` to `HomeView`**

  Replace the existing `headerSection` computed property with:
  ```swift
  private var headerSection: some View {
      ZStack(alignment: .topTrailing) {
          AppTheme.Colors.primaryGradient
              .ignoresSafeArea(edges: .top)

          // Decorative circles
          Circle()
              .fill(Color.white.opacity(0.07))
              .frame(width: 120, height: 120)
              .offset(x: 40, y: -40)
          Circle()
              .fill(Color.white.opacity(0.07))
              .frame(width: 70, height: 70)
              .offset(x: -10, y: -10)

          VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
              Text("纺织工具")
                  .font(.system(size: 11, weight: .medium))
                  .foregroundColor(.white.opacity(0.7))
                  .kerning(0.5)
              Text("你好，欢迎使用")
                  .font(AppTheme.Typography.title2)
                  .foregroundColor(.white)
              Text("选择功能模块开始使用")
                  .font(.system(size: 13))
                  .foregroundColor(.white.opacity(0.75))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, AppTheme.Spacing.large)
          .padding(.top, AppTheme.Spacing.large)
          .padding(.bottom, AppTheme.Spacing.xLarge + 12)
      }
  }
  ```

- [ ] **Step 2: Replace `modulesSection` to use `AppListCard`**

  Replace the entire `modulesSection` computed property:
  ```swift
  private var modulesSection: some View {
      VStack(spacing: AppTheme.Spacing.small) {
          NavigationLink(destination: CalculationHomeView()) {
              AppListCard(
                  title: "费用计算",
                  subtitle: "纱价成本计算与历史记录",
                  icon: "function"
              )
          }
          .buttonStyle(PlainButtonStyle())

          NavigationLink(destination: quoteDestination) {
              AppListCard(
                  title: "报价审批查询",
                  subtitle: "ERP 报价数据查询与审批",
                  icon: "doc.text.magnifyingglass"
              )
          }
          .buttonStyle(PlainButtonStyle())
      }
      .padding(.horizontal, AppTheme.Spacing.large)
      .padding(.top, -12)  // overlap banner bottom curve
  }
  ```

- [ ] **Step 3: Update `body` — remove `groupedBackground`, replace bottom padding**

  In `body`, change:
  - Remove `AppTheme.Colors.groupedBackground.ignoresSafeArea()` ZStack background
  - Change `.padding(.bottom, 100)` to `.padding(.bottom, AppTheme.Spacing.tabBarClearance)`
  - The `ScrollView` should now sit inside a plain `VStack`:
  ```swift
  var body: some View {
      NavigationStack {
          ScrollView(showsIndicators: false) {
              VStack(spacing: 0) {
                  headerSection
                  modulesSection
                      .padding(.top, AppTheme.Spacing.medium)
              }
              .padding(.bottom, AppTheme.Spacing.tabBarClearance)
          }
          .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
          .toolbar(.hidden, for: .navigationBar)
      }
  }
  ```

- [ ] **Step 4: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/HomeView.swift && \
  git commit -m "feat: HomeView — brand banner, white AppListCard, tabBarClearance"
  ```

---

## Task 4: CalculationHomeView — AppListCard + System Nav

**Files:**
- Modify: `CostCalculatorApp/Views/Calculator/CalculationHomeView.swift`

- [ ] **Step 1: Remove `customNavHeader`, adopt system nav bar**

  Replace the current `body` (which starts with a `VStack` containing `customNavHeader`) with:
  ```swift
  var body: some View {
      ScrollView(showsIndicators: false) {
          VStack(spacing: AppTheme.Spacing.medium) {
              VStack(spacing: AppTheme.Spacing.small) {
                  NavigationLink(destination: CostCalculatorView()) {
                      AppListCard(
                          title: "单材料纱价计算",
                          subtitle: "快速计算单一材料成本",
                          icon: "doc.text.magnifyingglass"
                      )
                  }
                  .buttonStyle(PlainButtonStyle())

                  NavigationLink(destination: CostCalculatorViewWithMaterial()) {
                      AppListCard(
                          title: "多材料纱价计算",
                          subtitle: "支持多种材料组合计算",
                          icon: "doc.on.doc"
                      )
                  }
                  .buttonStyle(PlainButtonStyle())

                  Button(action: { showingHistory = true }) {
                      AppListCard(
                          title: "历史记录",
                          subtitle: "查看所有计算记录",
                          icon: "clock.arrow.circlepath"
                      )
                  }
                  .buttonStyle(PlainButtonStyle())
              }
          }
          .padding(.horizontal, AppTheme.Spacing.large)
          .padding(.vertical, AppTheme.Spacing.medium)
          .padding(.bottom, AppTheme.Spacing.tabBarClearance)
      }
      .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
      .navigationTitle("费用计算")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $showingHistory) {
          NavigationStack {
              HistoryView()
                  .toolbar {
                      ToolbarItem(placement: .topBarTrailing) {
                          Button("关闭") { showingHistory = false }
                              .foregroundColor(AppTheme.Colors.primary)
                      }
                  }
          }
      }
  }
  ```

- [ ] **Step 2: Remove unused `@Environment(\.dismiss)` and `customNavHeader` imports**

  Delete `@Environment(\.dismiss) private var dismiss` from the top of the struct since it is no longer used.

- [ ] **Step 3: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/Calculator/CalculationHomeView.swift && \
  git commit -m "feat: CalculationHomeView — AppListCard, system nav bar, NavigationStack sheet"
  ```

---

## Task 5: StatisticHomeView — Banner + NavigationStack + Grouped Rows

**Files:**
- Modify: `CostCalculatorApp/Views/Statistic/StatisticHomeView.swift`

- [ ] **Step 1: Replace `NavigationView` with `NavigationStack` and add banner**

  Replace the entire `body` with:
  ```swift
  var body: some View {
      NavigationStack {
          ScrollView(showsIndicators: false) {
              VStack(spacing: 0) {
                  bannerHeader
                  statsContent
                      .padding(.top, AppTheme.Spacing.medium)
              }
              .padding(.bottom, AppTheme.Spacing.tabBarClearance)
          }
          .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
          .toolbar(.hidden, for: .navigationBar)
      }
  }
  ```

- [ ] **Step 2: Add `bannerHeader` computed property**

  Add a new computed property:
  ```swift
  private var bannerHeader: some View {
      ZStack(alignment: .topTrailing) {
          AppTheme.Colors.primaryGradient
              .ignoresSafeArea(edges: .top)

          Circle()
              .fill(Color.white.opacity(0.07))
              .frame(width: 120, height: 120)
              .offset(x: 40, y: -40)

          VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
              Text("数据概览")
                  .font(.system(size: 11, weight: .medium))
                  .foregroundColor(.white.opacity(0.7))
                  .kerning(0.5)
              Text("统计分析")
                  .font(AppTheme.Typography.title2)
                  .foregroundColor(.white)
              Text("查看您的计算数据统计")
                  .font(.system(size: 13))
                  .foregroundColor(.white.opacity(0.75))

              // Quick-stat chips — data comes from existing FetchRequest computed properties
              HStack(spacing: AppTheme.Spacing.xSmall) {
                  statChip("总计算 \(records.count) 次")
                  statChip("今日 \(todayRecordsCount) 次")
              }
              .padding(.top, AppTheme.Spacing.xxSmall)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, AppTheme.Spacing.large)
          .padding(.top, AppTheme.Spacing.large)
          .padding(.bottom, AppTheme.Spacing.xLarge + 12)
      }
  }

  private func statChip(_ text: String) -> some View {
      Text(text)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, AppTheme.Spacing.small)
          .padding(.vertical, 4)
          .background(Color.white.opacity(0.18))
          .clipShape(Capsule())
  }
  ```

- [ ] **Step 3: Add `statsContent` — group `StatisticRow` instances**

  Add a `statsContent` computed property that wraps each stat section in a grouped container:
  ```swift
  private var statsContent: some View {
      VStack(spacing: AppTheme.Spacing.large) {
          statGroup(title: "月度统计", rows: [
              ("本月计算次数", "\(currentMonthRecordsCount) 次", "calendar"),
              ("本月平均成本", String(format: "¥%.2f", currentMonthAverageCost), "chart.line.uptrend.xyaxis"),
              ("本月总产量", String(format: "%.2f 米", currentMonthTotalProduction), "ruler")
          ])
          statGroup(title: "材料使用统计", rows: [
              ("平均经纱重量", String(format: "%.2f g/m", averageWarpWeight), "scalemass"),
              ("平均纬纱重量", String(format: "%.2f g/m", averageWeftWeight), "scalemass"),
              ("平均日产量", String(format: "%.2f 米/天", averageDailyProduct), "timer")
          ])
          statGroup(title: "成本构成", rows: [
              ("平均经纱成本", String(format: "¥%.2f", averageWarpCost), "yensign.circle"),
              ("平均纬纱成本", String(format: "¥%.2f", averageWeftCost), "yensign.circle"),
              ("平均人工成本", String(format: "¥%.2f", averageLaborCost), "person.circle"),
              ("平均牵经成本", String(format: "¥%.2f", averageWarpingCost), "gearshape.circle")
          ])
      }
      .padding(.horizontal, AppTheme.Spacing.large)
  }

  private func statGroup(title: String, rows: [(String, String, String)]) -> some View {
      VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
          Text(title)
              .font(AppTheme.Typography.headline)
              .foregroundColor(AppTheme.Colors.primaryText)

          VStack(spacing: 0) {
              ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                  StatisticRow(title: row.0, value: row.1, icon: row.2)
                      .background(AppTheme.Colors.background)
                  if index < rows.count - 1 {
                      Divider()
                          .padding(.leading, 46)
                  }
              }
          }
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
          .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
      }
  }
  ```

- [ ] **Step 4: Update `StatisticRow` — remove per-row shadow**

  In `StatisticRow.body`, remove the `.shadow(...)` modifier at the end. The shadow is now on the group container.

  Also replace `.cornerRadius(AppTheme.CornerRadius.medium)` with `.clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))`.

- [ ] **Step 5: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/Statistic/StatisticHomeView.swift && \
  git commit -m "feat: StatisticHomeView — banner with stat chips, NavigationStack, grouped rows"
  ```

---

## Task 6: ProfileView — Banner + Fix Nav + Migrate Sub-views

**Files:**
- Modify: `CostCalculatorApp/Views/Settings/ProfileView.swift`

- [ ] **Step 1: Replace `.navigationBarHidden` with `.toolbar(.hidden, for: .navigationBar)`**

  In `ProfileView.body`, inside the `NavigationStack`, change:
  ```swift
  // Remove this:
  .navigationBarHidden(true)
  // Add this (on the ScrollView or ZStack, inside NavigationStack):
  .toolbar(.hidden, for: .navigationBar)
  ```

- [ ] **Step 2: Replace `headerSection` with a banner**

  Replace the existing `headerSection` computed property:
  ```swift
  private var headerSection: some View {
      ZStack(alignment: .topTrailing) {
          AppTheme.Colors.primaryGradient
              .ignoresSafeArea(edges: .top)

          Circle()
              .fill(Color.white.opacity(0.07))
              .frame(width: 120, height: 120)
              .offset(x: 40, y: -40)

          VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
              Text("设置")
                  .font(.system(size: 11, weight: .medium))
                  .foregroundColor(.white.opacity(0.7))
                  .kerning(0.5)
              Text("settings".localized())
                  .font(AppTheme.Typography.title2)
                  .foregroundColor(.white)
              Text("个性化与账户设置")
                  .font(.system(size: 13))
                  .foregroundColor(.white.opacity(0.75))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, AppTheme.Spacing.large)
          .padding(.top, AppTheme.Spacing.large)
          .padding(.bottom, AppTheme.Spacing.xLarge + 12)
      }
  }
  ```

- [ ] **Step 3: Update `body` — fix bottom padding**

  Change `.padding(.bottom, 100)` → `.padding(.bottom, AppTheme.Spacing.tabBarClearance)`

  Update the body so `headerSection` is the first item in the `ScrollView VStack` and the ZStack background is removed (banner provides the top color):
  ```swift
  var body: some View {
      NavigationStack {
          ScrollView(showsIndicators: false) {
              VStack(spacing: 0) {
                  headerSection
                  VStack(spacing: AppTheme.Spacing.medium) {
                      aiSettingsCard
                      appSettingsCard
                      aboutCard
                      versionInfo
                  }
                  .padding(.horizontal, AppTheme.Spacing.large)
                  .padding(.top, AppTheme.Spacing.medium)
                  .padding(.bottom, AppTheme.Spacing.tabBarClearance)
              }
          }
          .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
          .toolbar(.hidden, for: .navigationBar)
      }
      // ... rest of modifiers unchanged
  }
  ```

- [ ] **Step 4: Migrate sheet sub-views from `NavigationView` to `NavigationStack`**

  In `ProfileView.swift`, locate the six sheet sub-view structs. Each one has this pattern:
  ```swift
  // BEFORE (in each sub-view):
  NavigationView {
      // content
  }
  // AFTER:
  NavigationStack {
      // content (unchanged)
  }
  ```
  Apply to all six: `AISettingsView`, `AppSettingsView`, `AboutView`, `CloudKitSettingsView`, `LanguageSettingsView`, `ModelPickerSheet`.

  Also find any `.navigationBarItems(...)` usage in these sub-views and replace with:
  ```swift
  .toolbar {
      ToolbarItem(placement: .topBarTrailing) { /* button */ }
  }
  ```

- [ ] **Step 5: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/Settings/ProfileView.swift && \
  git commit -m "feat: ProfileView — banner, NavigationStack, migrate 6 sub-views"
  ```

---

## Task 7: ChatView — Banner + NavigationStack Calculator Sheet

**Files:**
- Modify: `CostCalculatorApp/Views/Chat/ChatView.swift`

- [ ] **Step 1: Replace `headerBar` with a brand banner**

  The current `headerBar` has two functional buttons that must be preserved:
  - Left: `bubble.left.and.bubble.right` → opens conversation list
  - Right: `square.and.pencil` → creates new conversation

  Replace the `headerBar` computed property:
  ```swift
  private var headerBar: some View {
      ZStack {
          AppTheme.Colors.primaryGradient
              .ignoresSafeArea(edges: .top)

          Circle()
              .fill(Color.white.opacity(0.07))
              .frame(width: 100, height: 100)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .offset(x: 30, y: -20)

          HStack {
              Button {
                  viewModel.loadConversations()
                  showConversationList = true
              } label: {
                  Image(systemName: "bubble.left.and.bubble.right")
                      .font(.system(size: 18, weight: .medium))
                      .foregroundColor(.white.opacity(0.9))
              }

              Spacer()

              VStack(spacing: 2) {
                  Text("织梦·雅集")
                      .font(AppTheme.Typography.headline)
                      .foregroundColor(.white)
                  Text("AI 纺织助手")
                      .font(.system(size: 11))
                      .foregroundColor(.white.opacity(0.7))
              }

              Spacer()

              Button {
                  viewModel.createNewConversation()
              } label: {
                  Image(systemName: "square.and.pencil")
                      .font(.system(size: 18, weight: .medium))
                      .foregroundColor(.white.opacity(0.9))
              }
          }
          .padding(.horizontal, AppTheme.Spacing.medium)
          .padding(.top, AppTheme.Spacing.small)
          .padding(.bottom, AppTheme.Spacing.medium)
      }
  }
  ```

- [ ] **Step 2: Verify NavigationStack need**

  `ChatView` currently has no outer `NavigationStack` — all modals use `.sheet()` / `.fullScreenCover()`, not `NavigationLink` push. No `NavigationStack` wrapper is needed on the root body. Skip this if no push-navigation sub-pages exist.

- [ ] **Step 3: Fix calculator sheet — `NavigationView` → `NavigationStack`**

  In the `.sheet(isPresented: $showCalculator)` modifier, change:
  ```swift
  // BEFORE:
  NavigationView {
      Group { ... }
      .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) { ... }
      }
  }
  // AFTER:
  NavigationStack {
      Group { ... }
      .toolbar {
          ToolbarItem(placement: .topBarTrailing) { ... }
      }
  }
  ```

- [ ] **Step 3: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/Chat/ChatView.swift && \
  git commit -m "feat: ChatView — brand banner preserving action buttons, NavigationStack sheet"
  ```

---

## Task 8: HistoryView — Fix Sheet NavigationView

**Files:**
- Modify: `CostCalculatorApp/Views/Calculator/HistoryView.swift`

- [ ] **Step 1: Migrate `recordToEdit` sheet from `NavigationView` to `NavigationStack`**

  Find the `.sheet(item: $recordToEdit)` modifier. Inside it, change:
  ```swift
  // BEFORE:
  NavigationView {
      EditCalculationView(record: record)
          .navigationBarItems(trailing: Button("关闭") { recordToEdit = nil })
  }
  // AFTER:
  NavigationStack {
      EditCalculationView(record: record)
          .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                  Button("关闭") { recordToEdit = nil }
                      .foregroundColor(AppTheme.Colors.primary)
              }
          }
  }
  ```

- [ ] **Step 2: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Views/Calculator/HistoryView.swift && \
  git commit -m "fix: HistoryView — migrate recordToEdit sheet to NavigationStack"
  ```

---

## Task 9: Remove FeatureCard and ModuleCard

**Files:**
- Modify: `CostCalculatorApp/Components/CustomComponents.swift`

- [ ] **Step 1: Verify no remaining call sites**

  Run:
  ```bash
  grep -r "FeatureCard\|ModuleCard" \
    /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp/CostCalculatorApp \
    --include="*.swift"
  ```
  Expected: zero output. If any appear, fix them before proceeding.

- [ ] **Step 2: Delete `FeatureCard` struct from `CustomComponents.swift`**

  Remove the entire `FeatureCard` struct (the one with `gradient: LinearGradient`, fixed `height: 160`).

- [ ] **Step 3: Delete `ModuleCard` struct from `HomeView.swift`**

  `ModuleCard` lives at the bottom of `HomeView.swift` (not in `CustomComponents.swift`). Remove it from there.

- [ ] **Step 4: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Components/CustomComponents.swift \
          CostCalculatorApp/Views/HomeView.swift && \
  git commit -m "chore: remove FeatureCard and ModuleCard (replaced by AppListCard)"
  ```

---

## Task 10: ViewModifiers Cleanup

**Files:**
- Modify: `CostCalculatorApp/Theme/ViewModifiers.swift`

- [ ] **Step 1: Grep for glassMorphism usage**

  ```bash
  grep -r "\.glassMorphism(" \
    /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp/CostCalculatorApp \
    --include="*.swift"
  ```
  Expected: zero output. If any matches appear, stop and investigate before deleting.

- [ ] **Step 2: Remove `GlassMorphismStyle`, `VisualEffectBlur`, and `.glassMorphism()` extension**

  Delete from `ViewModifiers.swift`:
  - The `GlassMorphismStyle` struct (the `// MARK: - Glass Morphism Style` section)
  - The `VisualEffectBlur` struct (the `// MARK: - Visual Effect Blur` section)
  - The `.glassMorphism(cornerRadius:)` line from the `View` extension at the bottom

- [ ] **Step 3: Build**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  xcodebuild -project CostCalculatorApp.xcodeproj -scheme CostCalculatorApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**
  ```bash
  cd /Users/zishuoli/Projects/XinzexiMobileDev/CostCalculatorApp && \
  git add CostCalculatorApp/Theme/ViewModifiers.swift && \
  git commit -m "chore: remove unused GlassMorphismStyle and VisualEffectBlur"
  ```
