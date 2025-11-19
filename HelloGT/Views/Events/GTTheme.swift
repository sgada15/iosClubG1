//
//  GTTheme.swift
//  BuzzBuddy
//
//  Created by Assistant on 11/19/25.
//

import SwiftUI

// MARK: - GT Theme Configuration

struct GTTheme {
    /// Configure the app with GT theme on launch
    static func configure() {
        // Set global accent color
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.tintColor = UIColor(Color.gtGold)
        }
        
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color.gtPastelYellow.opacity(0.1))
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gtNavy)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.gtNavy)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.gtPastelYellow.opacity(0.05))
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        print("🎨 GT Theme configured successfully!")
    }
}

// MARK: - View Extensions for Easy GT Theming

extension View {
    /// Apply GT-themed background to the entire view
    func gtBackground() -> some View {
        self.background(
            LinearGradient.gtBackgroundGradient
                .ignoresSafeArea()
        )
    }
    
    /// Apply GT-themed card styling
    func asGTCard(isPressed: Bool = false) -> some View {
        self
            .padding(16)
            .gtCardStyle(isPressed: isPressed)
    }
    
    /// Apply GT-themed section header styling
    func asGTSectionHeader() -> some View {
        self
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.gtNavy)
            .padding(.horizontal, 20)
            .padding(.top, 16)
    }
}