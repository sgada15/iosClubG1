//
//  GTColors.swift
//  BuzzBuddy
//
//  Created by Assistant on 11/19/25.
//

import SwiftUI

extension Color {
    // MARK: - Georgia Tech Colors
    
    /// Georgia Tech Gold (Primary Brand Color)
    static let gtGold = Color(red: 0.898, green: 0.722, blue: 0.200) // #E5B833
    
    /// Georgia Tech Pastel Yellow (Lighter, softer version)
    static let gtPastelYellow = Color(red: 0.980, green: 0.920, blue: 0.600) // #FAEB99
    
    /// Georgia Tech Navy (Primary Dark)
    static let gtNavy = Color(red: 0.000, green: 0.156, blue: 0.333) // #002855
    
    /// Georgia Tech Light Navy (Secondary)
    static let gtLightNavy = Color(red: 0.200, green: 0.350, blue: 0.500) // #335980
    
    /// Georgia Tech White
    static let gtWhite = Color.white
    
    /// Georgia Tech Buzz Gold (Vibrant accent)
    static let gtBuzzGold = Color(red: 1.000, green: 0.800, blue: 0.000) // #FFCC00
    
    // MARK: - Semantic GT Colors
    
    /// Primary accent color for the app
    static let gtPrimary = gtGold
    
    /// Secondary accent color
    static let gtSecondary = gtPastelYellow
    
    /// Background colors
    static let gtBackground = Color(.systemBackground)
    static let gtSecondaryBackground = gtPastelYellow.opacity(0.05)
    
    /// Card background with subtle GT yellow tint
    static let gtCardBackground = gtPastelYellow.opacity(0.08)
    
    /// Text colors
    static let gtPrimaryText = Color.primary
    static let gtSecondaryText = Color.secondary
    
    /// Button colors
    static let gtButtonPrimary = gtGold
    static let gtButtonSecondary = gtLightNavy
    
    /// Status colors with GT theming
    static let gtSuccess = Color.green
    static let gtWarning = gtBuzzGold
    static let gtError = Color.red
}

// MARK: - Material Extensions

extension Color {
    /// GT-themed glass tint for modern UI
    static let gtGlassTint = gtPastelYellow.opacity(0.3)
    
    /// GT-themed card material
    static let gtCardMaterial = gtPastelYellow.opacity(0.1)
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// GT Gold gradient
    static let gtGoldGradient = LinearGradient(
        colors: [Color.gtBuzzGold, Color.gtGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// GT Background gradient
    static let gtBackgroundGradient = LinearGradient(
        colors: [Color.gtSecondaryBackground, Color.gtBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// GT Card gradient
    static let gtCardGradient = LinearGradient(
        colors: [Color.gtCardBackground, Color.gtPastelYellow.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Extensions

extension View {
    /// GT-themed card shadow
    func gtCardShadow() -> some View {
        self.shadow(
            color: Color.gtGold.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    /// GT-themed soft shadow
    func gtSoftShadow() -> some View {
        self.shadow(
            color: Color.gtPastelYellow.opacity(0.2),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    /// GT-themed button shadow
    func gtButtonShadow() -> some View {
        self.shadow(
            color: Color.gtGold.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - BuzzBuddy UI Styles

struct BuzzBuddyButtonStyle: ButtonStyle {
    let variant: BuzzBuddyButtonVariant
    
    enum BuzzBuddyButtonVariant {
        case primary
        case secondary  
        case outline
        case glass
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(backgroundView)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .gtButtonShadow()
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .glass:
            return .white
        case .secondary:
            return .gtNavy
        case .outline:
            return .gtGold
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient.gtGoldGradient)
        case .secondary:
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color.gtPastelYellow, Color.gtPastelYellow.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        case .outline:
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gtGold, lineWidth: 2)
                .background(Color.clear)
        case .glass:
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gtGlassTint)
                )
        }
    }
}

// MARK: - Button Style Convenience Extensions

extension ButtonStyle where Self == BuzzBuddyButtonStyle {
    static var gtPrimary: BuzzBuddyButtonStyle {
        BuzzBuddyButtonStyle(variant: .primary)
    }
    
    static var gtSecondary: BuzzBuddyButtonStyle {
        BuzzBuddyButtonStyle(variant: .secondary)
    }
    
    static var gtOutline: BuzzBuddyButtonStyle {
        BuzzBuddyButtonStyle(variant: .outline)
    }
    
    static var gtGlass: BuzzBuddyButtonStyle {
        BuzzBuddyButtonStyle(variant: .glass)
    }
}

// MARK: - BuzzBuddy Card Style

struct BuzzBuddyCardStyle: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient.gtCardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gtPastelYellow.opacity(0.2), lineWidth: 1)
                    )
            )
            .gtCardShadow()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

extension View {
    func gtCardStyle(isPressed: Bool = false) -> some View {
        self.modifier(BuzzBuddyCardStyle(isPressed: isPressed))
    }
}

// MARK: - GT Navigation Bar Style

extension View {
    func gtNavigationBarStyle() -> some View {
        self
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.gtPastelYellow.opacity(0.1), for: .navigationBar)
    }
}

// MARK: - GT Tab Bar Style

extension View {
    func gtTabBarStyle() -> some View {
        self
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.gtPastelYellow.opacity(0.05), for: .tabBar)
            .accentColor(.gtGold)
    }
}