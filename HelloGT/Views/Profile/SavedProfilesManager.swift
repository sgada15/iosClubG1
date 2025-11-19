//
//  SavedProfilesManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SavedProfilesManager: ObservableObject {
    @Published var savedProfiles: [UserProfile] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedProfilesKey = "savedProfiles"
    
    init() {
        loadSavedProfiles()
    }
    
    // MARK: - Save/Unsave Functions
    
    func saveProfile(_ profile: UserProfile) {
        // Check if already saved
        if !savedProfiles.contains(where: { $0.id == profile.id }) {
            savedProfiles.append(profile)
            persistSavedProfiles()
            print("💾 Saved profile: \(profile.name)")
        }
    }
    
    func unsaveProfile(_ profile: UserProfile) {
        savedProfiles.removeAll { $0.id == profile.id }
        persistSavedProfiles()
        print("🗑️ Removed saved profile: \(profile.name)")
    }
    
    func isProfileSaved(_ profile: UserProfile) -> Bool {
        return savedProfiles.contains { $0.id == profile.id }
    }
    
    // MARK: - Persistence
    
    private func persistSavedProfiles() {
        do {
            let data = try JSONEncoder().encode(savedProfiles)
            userDefaults.set(data, forKey: savedProfilesKey)
            print("✅ Persisted \(savedProfiles.count) saved profiles")
        } catch {
            print("❌ Failed to persist saved profiles: \(error)")
        }
    }
    
    private func loadSavedProfiles() {
        guard let data = userDefaults.data(forKey: savedProfilesKey) else {
            print("📭 No saved profiles found in UserDefaults")
            return
        }
        
        do {
            savedProfiles = try JSONDecoder().decode([UserProfile].self, from: data)
            print("✅ Loaded \(savedProfiles.count) saved profiles from UserDefaults")
        } catch {
            print("❌ Failed to load saved profiles: \(error)")
            savedProfiles = []
        }
    }
}
