//
//  CalculationHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//

import SwiftUI

struct CalculationHomeView: View {
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        // Header
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                            Text("费用计算")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundColor(AppTheme.Colors.primaryText)
                            
                            Text("选择计算模式开始")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.top, AppTheme.Spacing.large)
                        
                        // Feature Cards
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
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHistory) {
                NavigationView {
                    HistoryView()
                        .navigationBarItems(trailing: Button("关闭") {
                            showingHistory = false
                        })
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
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(value)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.shadow, radius: 4, x: 0, y: 2)
    }
}

struct CalculationHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CalculationHomeView()
    }
}

