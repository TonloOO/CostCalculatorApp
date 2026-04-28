# 跨平台重建设计文档 (Expo / React Native)

**日期：** 2026-03-30
**目标平台：** iOS、Android
**技术方向：** 从现有 SwiftUI iOS 应用迁移至 Expo + React Native 新项目

---

## 背景

现有 CostCalculatorApp 是一个面向中文纺织行业用户的 SwiftUI iOS 原生应用（55个 Swift 文件）。为扩展至 Android 平台，决定用 Expo 新建跨平台版本，复用现有后端 API 和业务逻辑。

---

## 技术栈

| 层级 | 选型 | 说明 |
|------|------|------|
| 框架 | Expo (managed workflow) | 简化构建配置，适合 web 背景开发者 |
| 语言 | TypeScript | 类型安全，与 Next.js 生态一致 |
| 路由 | Expo Router | 文件路由，与 Next.js `app/` 目录一致 |
| 样式 | NativeWind (Tailwind CSS) | 统一样式语法，降低学习成本 |
| 状态管理 | Zustand | 轻量、简洁，适合本项目规模 |
| 本地存储 | AsyncStorage | 替代 Core Data，存储计算历史等本地数据 |
| 安全存储 | expo-secure-store | 替代 Keychain，存储 token / 密码 |
| HTTP 请求 | Axios | API 调用（聊天接口 + 报价 ERP 接口） |
| 图片选取 | expo-image-picker | 纺织品识别图片上传 |
| SSE 流式消息 | react-native-sse | 替代原生 EventSource，支持 AI 对话流式输出 |

---

## 项目结构

```
app/
  (tabs)/
    index.tsx          # 费用计算（主页）
    quote.tsx          # 报价管理
    chat.tsx           # AI 对话
    statistics.tsx     # 统计
  _layout.tsx          # Tab 导航配置
  +not-found.tsx

services/
  chatApi.ts           # 复用现有 SSE 聊天接口 (https://zscy.space/api/v1/sse)
  quoteApi.ts          # 复用现有报价 ERP API
  recognitionApi.ts    # 纺织品识别接口

lib/
  calculator.ts        # 纯 TS 计算逻辑（从 Calculator.swift 移植）
  inputValidator.ts    # 输入验证（从 InputValidator.swift 移植）
  constants.ts         # 计算常量（从 CalculationConstants.swift 移植）

stores/
  calculationStore.ts  # 计算状态 + 历史记录
  quoteStore.ts        # 报价状态
  chatStore.ts         # 对话状态
  userStore.ts         # 用户 / 认证状态

components/
  calculator/          # 费用计算相关组件
  quote/               # 报价相关组件
  chat/                # 对话相关组件
  shared/              # 通用组件（按钮、输入框等）

constants/
  theme.ts             # 颜色、字体、间距（对应现有 Theme 目录）
```

---

## 功能模块

### 1. 费用计算（核心）
- 单材料计算器（对应 `CostCalculatorView`）
- 多材料计算器（对应 `CostCalculatorViewWithMaterial`）
- 计算历史记录（AsyncStorage 持久化，替代 Core Data）
- 计算常量配置

### 2. 报价管理
- 登录 / 认证（token 存储用 expo-secure-store）
- 报价列表、详情、创建
- 与现有 ERP API 对接，接口不变

### 3. AI 对话
- SSE 流式消息（react-native-sse 实现）
- 会话历史列表
- 图片上传识别（expo-image-picker）

### 4. 统计
- 计算数据可视化
- 基于本地 AsyncStorage 数据

---

## 关键技术决策

### 计算逻辑移植
`Calculator.swift` 中的纺织成本计算逻辑为纯数学运算，无 UI 依赖，可直接移植为 `lib/calculator.ts` 纯函数。这是迁移中最高价值的复用点。

### 数据持久化
原项目使用 Core Data + CloudKit 同步。新版本使用 AsyncStorage 本地存储，**不做云同步**（可作为后续迭代功能）。

### SSE 流式聊天
React Native 无原生 `EventSource` 支持，使用 `react-native-sse` 库处理 SSE 连接，API 地址和参数与现有 iOS 版本完全相同。

### 云端不变
后端 API（聊天、报价 ERP）完全复用，新项目只改客户端，不涉及服务端改动。

---

## 不在本次范围内

- 微信小程序支持
- CloudKit / 云端数据同步
- 本地 LLM（LLamaManager）集成
- MarkdownUI 以外的富文本渲染（用 react-native-markdown-display 替代）

---

## 风险点

| 风险 | 程度 | 应对 |
|------|------|------|
| SSE 在 RN 中的兼容性 | 中 | 早期验证 react-native-sse，准备 polling fallback |
| Expo managed workflow 的原生模块限制 | 低 | 本项目无特殊原生需求，managed 足够 |
| 计算逻辑移植误差 | 中 | 移植后用现有 Swift 测试用例交叉验证 |
