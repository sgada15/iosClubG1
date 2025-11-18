//
//  AppState.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var hasCompletedLaunch = false
    @Published var isShowingOnboarding = false
    
    func completeLaunch() {
        hasCompletedLaunch = true
    }
    
    func showOnboarding() {
        isShowingOnboarding = true
    }
    
    func completeOnboarding() {
        isShowingOnboarding = false
    }
}

