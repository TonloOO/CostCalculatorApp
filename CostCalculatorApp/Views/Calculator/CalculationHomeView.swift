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
                VStack {
                    NavigationLink(destination: CostCalculatorView()) {
                        ZStack {
                            GeometryReader { geometry in
                                Image("star")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 300)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                            .frame(height: 300) // Set a fixed height for the container
                            Text("单材料纱价费用计算")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
                VStack {
                    NavigationLink(destination: CostCalculatorViewWithMaterial()) {
                        ZStack {
                            GeometryReader { geometry in
                                Image("sky")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 300)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                            .frame(height: 300) // Set a fixed height for the container
                            Text("多材料纱价费用计算")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
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

