//
//  SavedProfilesManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class SavedProfilesManager: ObservableObject {
    @Published var savedProfiles: [UserProfile] = []
    
    private let userDefaults = UserDefaults.standard
    
    // User-specific key to prevent cross-user data leakage
    private var savedProfilesKey: String {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Fallback to a default key if user not logged in (shouldn't happen in normal flow)
            print("⚠️ WARNING: No user logged in, using default key")
            return "savedProfiles_default"
        }
        return "savedProfiles_\(userId)"
    }
    
    init() {
        loadSavedProfiles()
        
        // Observe auth state changes to reload saved profiles when user changes
        NotificationCenter.default.addObserver(
            forName: .init("AuthStateDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSavedProfiles()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Public method to reload saved profiles (call this when user logs in)
    func reloadSavedProfiles() {
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
        guard Auth.auth().currentUser != nil else {
            print("⚠️ Cannot persist saved profiles: No user logged in")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(savedProfiles)
            userDefaults.set(data, forKey: savedProfilesKey)
            print("✅ Persisted \(savedProfiles.count) saved profiles for user: \(Auth.auth().currentUser?.uid ?? "unknown")")
        } catch {
            print("❌ Failed to persist saved profiles: \(error)")
        }
    }
    
    private func loadSavedProfiles() {
        guard Auth.auth().currentUser != nil else {
            print("⚠️ Cannot load saved profiles: No user logged in")
            savedProfiles = []
            return
        }
        
        guard let data = userDefaults.data(forKey: savedProfilesKey) else {
            print("📭 No saved profiles found in UserDefaults for user: \(Auth.auth().currentUser?.uid ?? "unknown")")
            return
        }
        
        do {
            savedProfiles = try JSONDecoder().decode([UserProfile].self, from: data)
            print("✅ Loaded \(savedProfiles.count) saved profiles for user: \(Auth.auth().currentUser?.uid ?? "unknown")")
        } catch {
            print("❌ Failed to load saved profiles: \(error)")
            savedProfiles = []
        }
    }
    
    // Call this when user logs out to clear the saved profiles
    func clearSavedProfiles() {
        savedProfiles = []
        if let userId = Auth.auth().currentUser?.uid {
            userDefaults.removeObject(forKey: "savedProfiles_\(userId)")
        }
    }
}