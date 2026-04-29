//
//  CalculationHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//

import SwiftUI

struct CalculationHomeView: View {
    @State private var showingHistory = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            customNavHeader(
                title: "费用计算",
                backLabel: "首页",
                dismiss: dismiss
            )
            .padding(.bottom, AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.groupedBackground)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.large) {
                    Text("选择计算模式开始")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.large)
                    
                    VStack(spacing: AppTheme.Spacing.medium) {
                        NavigationLink(destination: CostCalculatorView()) {
                            FeatureCard(
                                title: "单材料纱价计算",
                                subtitle: "快速计算单一材料成本",
                                icon: "doc.text.magnifyingglass",
                                gradient: AppTheme.Colors.cardGradient1,
                                action: {}
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: CostCalculatorViewWithMaterial()) {
                            FeatureCard(
                                title: "多材料纱价计算",
                                subtitle: "支持多种材料组合计算",
                                icon: "doc.on.doc",
                                gradient: AppTheme.Colors.cardGradient2,
                                action: {}
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            FeatureCard(
                                title: "历史记录",
                                subtitle: "查看所有计算记录",
                                icon: "clock.arrow.circlepath",
                                gradient: AppTheme.Colors.cardGradient3,
                                action: {}
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, AppTheme.Spacing.large)
                }
                .padding(.bottom, 100)
            }
        }
        .background(AppTheme.Colors.groupedBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                HistoryView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") { showingHistory = false }
                        }
                    }
            }
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                
                Text(value)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.background)
        .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CalculationHomeView()
}

