//
//  Theme.swift
//  CostCalculatorApp
//
//  Created by AI Assistant on 2024-12-20.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color(hex: "5B67CA")
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "5B67CA"), Color(hex: "7B85E0")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Secondary Colors
        static let secondary = Color(hex: "8B95C9")
        static let accent = Color(hex: "FF6B6B")
        
        // Background Colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        static let groupedBackground = Color(UIColor.systemGroupedBackground)
        
        // Card Gradients
        static let cardGradient1 = LinearGradient(
            colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient2 = LinearGradient(
            colors: [Color(hex: "F093FB"), Color(hex: "F5576C")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient3 = LinearGradient(
            colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient4 = LinearGradient(
            colors: [Color(hex: "43E97B"), Color(hex: "38F9D7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Text Colors
        static let primaryText = Color(UIColor.label)
        static let secondaryText = Color(UIColor.secondaryLabel)
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        
        // Status Colors
        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FFC107")
        static let error = Color(hex: "F44336")
        static let info = Color(hex: "2196F3")
        
        // Shadow Color
        static let shadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Typography
    struct Typography {
        // Titles
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Custom
        static let buttonText = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let cardTitle = Font.system(size: 18, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let small = ShadowStyle(color: Colors.shadow, radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: Colors.shadow, radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: Colors.shadow, radius: 12, x: 0, y: 6)
        static let card = ShadowStyle(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
