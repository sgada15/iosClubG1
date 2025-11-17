//
//  HelloGTApp.swift
//  HelloGT
//
//  Created by Sanaa Gada on 10/30/25.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct HelloGTApp: App {
    init() {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully!")
        }
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}
