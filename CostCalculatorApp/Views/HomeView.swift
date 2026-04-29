//
//  HomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2026-03-06.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var authManager = QuoteAuthManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        headerSection
                        modulesSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text("纺织工具")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            Text("选择功能模块开始使用")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)
    }
    
    // MARK: - Modules
    
    private var modulesSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            NavigationLink(destination: CalculationHomeView()) {
                ModuleCard(
                    title: "费用计算",
                    subtitle: "纱价成本计算与历史记录",
                    icon: "function",
                    features: ["单材料纱价计算", "多材料纱价计算", "历史记录查询"],
                    gradient: AppTheme.Colors.cardGradient1
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: quoteDestination) {
                ModuleCard(
                    title: "报价审批查询",
                    subtitle: "ERP 报价数据查询与审批",
                    icon: "doc.text.magnifyingglass",
                    features: ["报价审批列表", "报价概览", "客户与状态筛选"],
                    gradient: AppTheme.Colors.cardGradient2
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.large)
    }
    
    @ViewBuilder
    private var quoteDestination: some View {
        if authManager.isLoggedIn {
            QuoteHomeView()
        } else {
            QuoteLoginGateView()
        }
    }
}

/// Wraps login → auto-navigate to QuoteHomeView on success
struct QuoteLoginGateView: View {
    @StateObject private var authManager = QuoteAuthManager.shared
    
    var body: some View {
        if authManager.isLoggedIn {
            QuoteHomeView()
        } else {
            QuoteLoginView()
        }
    }
}

// MARK: - Module Card

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let features: [String]
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(title)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            HStack(spacing: AppTheme.Spacing.xSmall) {
                ForEach(features, id: \.self) { feature in
                    Text(feature)
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    HomeView()
}
