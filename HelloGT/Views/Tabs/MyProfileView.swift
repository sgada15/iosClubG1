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
        id: "current-user",
        profilePhotoURL: nil,
        name: "Alex Johnson",
        username: "alexjohnson",
        year: "2025",
        major: "Computer Science",
        bio: "Computer Science student passionate about software development and outdoor adventures. Love building apps and capturing moments through photography.",
        interests: ["Coding", "Hiking", "Photography", "Music"],
        clubs: ["CS Club", "Outdoor Adventures", "Photography Society"],
        personalityAnswers: ["Problem solver", "Adventure seeker", "Creative", "Team player"]
    )
    
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading profile...")
            } else {
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
                            .environmentObject(authManager)
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
        }
        .onAppear {
            loadCurrentUserProfile()
        }
    }
    
    private func loadCurrentUserProfile() {
        isLoading = true
        
        // Update profile with current user info from auth
        if let user = authManager.user {
            // Load profile from Firebase
            Task {
                do {
                    if let loadedProfile = try await authManager.getCurrentUserProfile() {
                        await MainActor.run {
                            currentUserProfile = loadedProfile
                            isLoading = false
                        }
                    } else {
                        // No profile exists, update with user auth info
                        await MainActor.run {
                            currentUserProfile.id = user.uid
                            if let displayName = user.displayName, !displayName.isEmpty {
                                currentUserProfile.name = displayName
                            }
                            isLoading = false
                        }
                    }
                } catch {
                    print("Error loading user profile: \(error)")
                    // Fallback to updating with auth info
                    await MainActor.run {
                        currentUserProfile.id = user.uid
                        if let displayName = user.displayName, !displayName.isEmpty {
                            currentUserProfile.name = displayName
                        }
                        isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
}
