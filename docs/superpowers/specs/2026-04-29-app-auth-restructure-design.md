# App 登录外提与统计页改造设计

**Date**: 2026-04-29
**Author**: Claude (with Zishuo Li)
**Status**: Approved, ready for implementation
**Companion**: `xzx-mobile-dev/docs/superpowers/specs/2026-04-29-machine-status-api-design.md`

## 背景

`CostCalculatorApp` 当前架构：

- 顶层 `ContentView` 是 4 个 tab：Home / Chat / Statistic / Settings，全部对未登录用户开放
- 「报价审批查询」入口在 `HomeView` 模块卡片里，**模块级**登录闸口（`QuoteAuthManager.isLoggedIn` → `QuoteHomeView` 或 `QuoteLoginView`）
- 「统计」tab 用本地 Core Data 计算记录，与 ERP 无关
- 登录态通过 `QuoteAuthManager.shared`（`@Observable @MainActor`）管理，token 存 Keychain

现在要让登录变成**全局概念**：
- 未登录：App 仍可正常使用费用计算 / 聊天 / 设置
- 登录后：解锁两件事 ——「统计」tab（机台运行状态）+ Home 中「报价审批查询」入口

「机台运行状态」由配套 spec A 提供的 admin-only API 驱动。普通用户（业务员、经理）登录后能看报价但看不到统计 tab。

## 设计决策摘要

| 决策 | 选择 | 备注 |
|---|---|---|
| Tab 结构 | 动态：未登录 3 tab，登录后 4 tab | 「统计」tab 仅 admin 可见 |
| `QuoteAuthManager` | 改名为 `AuthManager` | Keychain account 名保持 `xzx_quote_*` 不动（向后兼容已登录用户） |
| 登录入口主位置 | Settings tab 顶部分组 | Home 报价卡片仍可触发登录（保留现有交互） |
| 报价模块登录闸口 | 移除 | 改为依赖全局 `auth.isLoggedIn`；如未登录，点 Home 报价卡片 → 跳 Settings 登录 |
| 统计 tab 内容 | 整段替换为机台运行状态三层视图 | 旧 Core Data 统计**删除**（用户未要求保留）|
| 刷新策略 | `.refreshable` 下拉刷新 + `onAppear` 首次加载 | 无定时轮询 |
| 401 处理 | 自动 logout → tab 消失 → 落回 Home | 复用 `QuoteAPIService` 现有模式 |
| 加载态 | `ProgressView` 占位 | 不做骨架屏 |
| 错误态 | `ContentUnavailableView` + 重试按钮 | |

## 文件级改动

### 重命名（无逻辑变动）

| Before | After |
|---|---|
| `Models/QuoteAuthManager.swift` | `Models/AuthManager.swift` |
| `Views/Quote/QuoteLoginView.swift` | `Views/Auth/LoginView.swift` |
| `class QuoteAuthManager` | `class AuthManager` |
| `struct QuoteLoginView` | `struct LoginView` |
| `struct AppSecretSettingView` | （保留原名，移到 `Views/Auth/`） |
| `QuoteAuthManager.shared` 全部引用 | `AuthManager.shared` |

`Views/HomeView.swift` 里的 `QuoteLoginGateView` 删除（不再需要）。

### 新增

```
Views/
├── Auth/
│   ├── LoginView.swift              # 原 QuoteLoginView，改名后挪进来
│   └── AppSecretSettingView.swift   # 原同名结构体，挪进来
└── Statistic/
    ├── StatisticHomeView.swift       # 重写：机台总览（A 层）
    ├── MachineListView.swift         # 新增：机台列表（B 层）
    ├── MachineDetailView.swift       # 新增：单机详情（C 层）

Models/
├── AuthManager.swift                  # 由 QuoteAuthManager 改名
├── MachineAPIService.swift            # 新增：调 /api/machine/*
└── MachineModels.swift                # 新增：响应模型
```

### 修改

- `ContentView.swift`：tab 改为动态（依赖 `AuthManager.shared.isLoggedIn`），`onChange` 处理登出时 selectedTab 回退
- `Views/HomeView.swift`：移除 `QuoteLoginGateView`，报价卡片直接判断 `auth.isLoggedIn`，未登录则触发跳 Settings tab + 提示登录
- `Views/Settings/ProfileView.swift`：顶部加「账户」分组（登录 / 已登录用户名 / 退出登录 / 应用密钥）
- `CostCalculatorApp.swift`：无需改（Core Data 仍要保留，费用计算用）

## ContentView 动态 Tab 草案

```swift
enum AppTab: Hashable {
    case home, chat, statistic, setting
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var auth = AuthManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    private var canSeeStatistic: Bool {
        auth.isLoggedIn && auth.role == "admin"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("tab_home".localized(),       systemImage: "house.circle",   value: .home)      { HomeView() }
            Tab("tab_chat".localized(),       systemImage: "message.circle", value: .chat)      { ChatView() }
            if canSeeStatistic {
                Tab("tab_statistics".localized(), systemImage: "chart.bar",  value: .statistic) { StatisticHomeView() }
            }
            Tab("tab_settings".localized(),   systemImage: "gearshape",      value: .setting)   { ProfileView() }
        }
        .id(languageManager.currentLanguage.rawValue)
        .onChange(of: canSeeStatistic) { _, canSee in
            if !canSee && selectedTab == .statistic { selectedTab = .home }
        }
    }
}
```

## ProfileView 顶部「账户」分组

未登录：
```
┌──────────────────────────────┐
│ 账户                          │
├──────────────────────────────┤
│  登录账号       →             │
│  应用密钥       未设置 →      │
└──────────────────────────────┘
```

已登录：
```
┌──────────────────────────────┐
│ 账户                          │
├──────────────────────────────┤
│  {userName}                   │
│  角色：管理员/业务员/经理     │
│  退出登录                  →  │
└──────────────────────────────┘
```

## 统计 Tab 三层视图

### A 层：StatisticHomeView（总览）

`NavigationStack` 包住三层视图。

布局（自上而下）：
1. 「今日」大数字卡片：活跃机台数 / 总产量(米) / 上报条数
2. 「最近 7 日趋势」折线图（`Charts` 框架，iOS 16+）：x=日期，y=活跃机台数 + y2=总产量
3. 「按状态分布」5 个 NavigationLink 按钮（点进 MachineListView，传 bucket 参数）：
   - 🟢 今日活跃 (count)
   - 🟡 昨日活跃 (count)
   - 🟠 2-7 天闲置 (count)
   - 🔴 7 天以上 (count)
   - ⚫ 从未上报 (count)

### B 层：MachineListView

参数：`bucket: MachineBucket`

`List` + 每行：
- 左：状态色点 + 机台号 + 机台名
- 右：最后上报时间（相对，如"5 分钟前 / 昨天 / 3 天前"）+ 24h 产量

点行 → push `MachineDetailView(equipmentNo:)`。

`.refreshable` 支持下拉刷新。

### C 层：MachineDetailView

参数：`equipmentNo: String`

布局：
1. 头部：机台号 / 名称 / 位置 / 状态色标签 / 最后上报时间
2. 时间窗口 segmented：7 天 / 14 天（默认）/ 30 天
3. 「日汇总」list：日期 + 当日总长 + 上报次数 + 班组（小标签）
4. 「最近 50 条落布」list：时间 + 布号 + 长度 + 工人 + 班组

## API Service 设计

```swift
@Observable
@MainActor
final class MachineAPIService {
    static let shared = MachineAPIService()
    private let api = QuoteAPIService.shared  // 复用 baseURL + auth header 注入

    func fetchOverview() async throws -> MachineOverview { ... }
    func fetchList(bucket: MachineBucket) async throws -> [MachineListItem] { ... }
    func fetchDetail(equipmentNo: String, days: Int) async throws -> MachineDetail { ... }
}
```

复用 `QuoteAPIService` 已有的：
- `baseURL` 管理
- 401 自动 logout 钩子
- `X-App-Secret` 注入

## 数据模型

```swift
enum MachineBucket: String, Codable, CaseIterable {
    case activeToday    = "active_today"
    case idleYesterday  = "idle_yesterday"
    case idle2to7d      = "idle_2_7d"
    case idleGt7d       = "idle_gt_7d"
    case neverReported  = "never_reported"

    var displayName: String { ... }   // 中文标签
    var color: Color        { ... }   // 状态色
}

struct MachineOverview: Codable { ... }
struct MachineListItem: Codable { ... }
struct MachineDetail: Codable { ... }
```

## 测试

`CostCalculatorAppTests` 加：
- `MachineAPIServiceTests.swift`：mock URLSession，验证三个 endpoint 的请求构造、响应解码、401 处理
- `MachineBucketTests.swift`：枚举映射、displayName、color

UI 测试不做（与 Quote 模块策略一致）。

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| `QuoteAuthManager` 改名涉及 ~10 个文件 | 一次性全局 grep 替换，保留 Keychain account 名不变以免老用户被强制登出 |
| 报价卡片去掉登录闸口后，未登录用户点击会困惑 | 跳 Settings tab + 一次性 toast「请先登录账号」 |
| Tab 数量动态变化时 selectedTab 失效 | `onChange(of: canSeeStatistic)` 回退到 `.home` |
| 统计 tab 旧 Core Data 内容删除后老用户感到丢失功能 | 用户已确认删除；如有反弹再重新评估 |

## YAGNI

不做：
- 通知/badge
- 离线缓存（每次拉新）
- 排序 / 搜索（330 台不需要）
- 多车间分组
- 推送通知
