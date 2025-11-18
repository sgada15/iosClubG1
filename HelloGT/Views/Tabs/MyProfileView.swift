//
//  MyProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import FirebaseAuth

struct MyProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Start with empty profile - will be loaded from Firebase or created
    @State private var currentUserProfile: UserProfile = UserProfile(
        id: "",
        profilePhotoURL: nil,
        name: "",
        username: "",
        year: "",
        major: "",
        bio: "",
        interests: [],
        clubs: [],
        personalityAnswers: ["", "", "", ""]
    )
    
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            OtherProfileDetailView(
                profile: currentUserProfile,
                isCurrentUser: true,
                onEdit: {
                    showEditProfile = true
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Profile") {
                            showEditProfile = true
                        }
                        
                        Divider()
                        
                        Button("Sign Out", role: .destructive) {
                            showSignOutAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                NavigationView {
                    EditProfileView(profile: $currentUserProfile)
                        .navigationTitle("Edit Profile")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .onAppear {
            loadCurrentUserProfile()
        }
    }
    
    private func loadCurrentUserProfile() {
        guard let user = authManager.user else { return }
        
        Task {
            do {
                print("🔍 Loading profile for user: \(user.email ?? "no email")")
                
                if let loadedProfile = try await authManager.getCurrentUserProfile() {
                    print("✅ Found existing profile: \(loadedProfile.name)")
                    await MainActor.run {
                        currentUserProfile = loadedProfile
                    }
                } else {
                    print("⚠️ No profile found, creating new one...")
                    if let newProfile = try await authManager.createProfileForCurrentUser() {
                        print("✅ Created new profile: \(newProfile.name)")
                        await MainActor.run {
                            currentUserProfile = newProfile
                        }
                    } else {
                        print("❌ Failed to create profile")
                    }
                }
            } catch {
                print("❌ Error loading/creating profile: \(error)")
                // Fallback: create basic profile with auth info
                await MainActor.run {
                    currentUserProfile.id = user.uid
                    currentUserProfile.name = user.displayName ?? "User"
                    currentUserProfile.username = user.email?.split(separator: "@").first?.lowercased() ?? "user"
                }
            }
        }
    }
}
