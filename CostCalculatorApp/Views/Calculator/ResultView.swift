//
//  ResultView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var calculationResults: CalculationResults
    var customerName: String
    var dismissAction: () -> Void
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        // Customer Info Card
                        if !customerName.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                                Text("客户信息")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                Text(customerName)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.primaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.medium)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        
                        // Main Result Card
                        VStack(spacing: AppTheme.Spacing.medium) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                                    Text("总费用")
                                        .font(AppTheme.Typography.caption1)
                                        .foregroundColor(AppTheme.Colors.secondaryText)
                                    
                                    Text("\(calculationResults.totalCost, specifier: "%.3f")")
                                        .font(AppTheme.Typography.largeTitle)
                                        .foregroundColor(AppTheme.Colors.accent)
                                    
                                    Text("元/米")
                                        .font(AppTheme.Typography.footnote)
                                        .foregroundColor(AppTheme.Colors.tertiaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                            .padding(AppTheme.Spacing.large)
                        }
                        .background(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent.opacity(0.1), AppTheme.Colors.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AppTheme.CornerRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Detail Cards
                        VStack(spacing: AppTheme.Spacing.small) {
                            SectionHeader(title: "成本明细")
                            
                            ResultCard(
                                title: "经纱成本",
                                value: String(format: "%.3f 元/米", calculationResults.warpCost),
                                icon: "arrow.up.right.circle"
                            )
                            
                            ResultCard(
                                title: "经纱克重",
                                value: String(format: "%.3f 克", calculationResults.warpWeight),
                                icon: "scalemass"
                            )
                            
                            ResultCard(
                                title: "纬纱成本",
                                value: String(format: "%.3f 元/米", calculationResults.weftCost),
                                icon: "arrow.down.left.circle"
                            )
                            
                            ResultCard(
                                title: "纬纱克重",
                                value: String(format: "%.3f 克", calculationResults.weftWeight),
                                icon: "scalemass"
                            )
                            
                            ResultCard(
                                title: "牵经费用",
                                value: String(format: "%.3f 元/米", calculationResults.warpingCost),
                                icon: "link.circle"
                            )
                            
                            ResultCard(
                                title: "工费",
                                value: String(format: "%.3f 元/米", calculationResults.laborCost),
                                icon: "person.circle"
                            )
                            
                            ResultCard(
                                title: "日产量",
                                value: String(format: "%.3f 米", calculationResults.dailyProduct),
                                icon: "calendar.circle"
                            )
                        }
                        
                        // Action Buttons
                        HStack(spacing: AppTheme.Spacing.medium) {
                            Button(action: {
                                showShareSheet = true
                            }) {
                                Label("分享", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .secondaryButton()
                            
                            Button(action: dismissAction) {
                                Text("完成")
                                    .frame(maxWidth: .infinity)
                            }
                            .primaryButton()
                        }
                        .padding(.top, AppTheme.Spacing.large)
                    }
                    .padding(AppTheme.Spacing.large)
                    .padding(.bottom, AppTheme.Spacing.xxLarge)
                }
            }
            .navigationTitle("计算结果")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    private func generateShareText() -> String {
        var text = "【纺织成本计算结果】\n"
        if !customerName.isEmpty {
            text += "客户：\(customerName)\n"
        }
        text += """
        
        总费用：\(String(format: "%.3f", calculationResults.totalCost)) 元/米
        
        明细：
        • 经纱成本：\(String(format: "%.3f", calculationResults.warpCost)) 元/米
        • 纬纱成本：\(String(format: "%.3f", calculationResults.weftCost)) 元/米
        • 牵经费用：\(String(format: "%.3f", calculationResults.warpingCost)) 元/米
        • 工费：\(String(format: "%.3f", calculationResults.laborCost)) 元/米
        • 日产量：\(String(format: "%.3f", calculationResults.dailyProduct)) 米
        """
        return text
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
