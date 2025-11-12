//
//  LaunchViewModel.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/12/25.

import Foundation
import Combine
import SwiftUI

class LaunchViewModel: ObservableObject {
    @Published var shouldNavigate = false

    func startLaunchSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.shouldNavigate = true
        }
    }
}
