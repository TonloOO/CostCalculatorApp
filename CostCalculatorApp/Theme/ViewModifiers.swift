//
//  ViewModifiers.swift
//  CostCalculatorApp
//
//  Created by AI Assistant on 2024-12-20.
//

import SwiftUI

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    var backgroundColor: Color = AppTheme.Colors.background
    var cornerRadius: CGFloat = AppTheme.CornerRadius.large
    var shadow: ShadowStyle = AppTheme.Shadow.card
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Gradient Card Style
struct GradientCardStyle: ViewModifier {
    var gradient: LinearGradient
    var cornerRadius: CGFloat = AppTheme.CornerRadius.large
    
    func body(content: Content) -> some View {
        content
            .background(gradient)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonModifier: ViewModifier {
    @State private var isPressed = false
    var isDisabled: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.buttonText)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                Group {
                    if isDisabled {
                        Color.gray.opacity(0.5)
                    } else {
                        AppTheme.Colors.primaryGradient
                    }
                }
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: isDisabled ? .clear : AppTheme.Colors.shadow, 
                   radius: isPressed ? 2 : 6, 
                   x: 0, 
                   y: isPressed ? 1 : 3)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                               pressing: { pressing in
                                   withAnimation(AppTheme.Animation.quick) {
                                       isPressed = pressing
                                   }
                               },
                               perform: {})
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.buttonText)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary, lineWidth: 2)
                    .background(Color.clear)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                               pressing: { pressing in
                                   withAnimation(AppTheme.Animation.quick) {
                                       isPressed = pressing
                                   }
                               },
                               perform: {})
    }
}

// MARK: - Text Field Style
struct CustomTextFieldStyle: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isFocused ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
            .focused($isFocused)
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(AppTheme.Colors.primaryGradient)
            .cornerRadius(28)
            .shadow(color: AppTheme.Colors.shadow, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                               pressing: { pressing in
                                   withAnimation(AppTheme.Animation.quick) {
                                       isPressed = pressing
                                   }
                               },
                               perform: {})
    }
}

// MARK: - Glass Morphism Style
struct GlassMorphismStyle: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.CornerRadius.large
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.white.opacity(0.1)
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 400 - 200)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(backgroundColor: Color = AppTheme.Colors.background,
                   cornerRadius: CGFloat = AppTheme.CornerRadius.large,
                   shadow: ShadowStyle = AppTheme.Shadow.card) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius, shadow: shadow))
    }
    
    func gradientCard(gradient: LinearGradient, cornerRadius: CGFloat = AppTheme.CornerRadius.large) -> some View {
        modifier(GradientCardStyle(gradient: gradient, cornerRadius: cornerRadius))
    }
    
    func primaryButton(isDisabled: Bool = false) -> some View {
        modifier(PrimaryButtonModifier(isDisabled: isDisabled))
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonModifier())
    }
    
    func customTextField() -> some View {
        modifier(CustomTextFieldStyle())
    }
    
    func floatingActionButton() -> some View {
        modifier(FloatingActionButtonStyle())
    }
    
    func glassMorphism(cornerRadius: CGFloat = AppTheme.CornerRadius.large) -> some View {
        modifier(GlassMorphismStyle(cornerRadius: cornerRadius))
    }
    
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}
