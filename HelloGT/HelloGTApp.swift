//
//  BuzzBuddyApp.swift
//  BuzzBuddy
//
//  Created by Sanaa Gada on 10/30/25.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct BuzzBuddyApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        FirebaseApp.configure()
        GTTheme.configure() // Apply GT theme globally
        print("✅ Firebase configured successfully!")
        print("🎨 BuzzBuddy Theme applied!")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.hasCompletedLaunch {
                    AuthenticationView()
                        .environmentObject(appState)
                        .transition(.opacity)
                } else {
                    LaunchView()
                        .environmentObject(appState)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: appState.hasCompletedLaunch)
        }
    }
}
