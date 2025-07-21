//
//  CalculationHomeView.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-05.
//

import SwiftUI

struct CalculationHomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink(destination: CostCalculatorView()) {
                        ZStack {
                            GeometryReader { geometry in
                                Image("star")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 180)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                            .frame(height: 180)
                            Text("单材料纱价费用计算")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    NavigationLink(destination: CostCalculatorViewWithMaterial()) {
                        ZStack {
                            GeometryReader { geometry in
                                Image("sky")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 180)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                            .frame(height: 180)
                            Text("多材料纱价费用计算")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    NavigationLink(destination: HistoryView()) {
                        ZStack {
                            GeometryReader { geometry in
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: geometry.size.width, height: 180)
                                .cornerRadius(10)
                            }
                            .frame(height: 180)
                            Text("历史记录")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
            }
            .navigationTitle("费用计算")
        }
    }
}

struct CalculationHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CalculationHomeView()
    }
}

