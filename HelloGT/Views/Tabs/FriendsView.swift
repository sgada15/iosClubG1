//
//  FriendsView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import FirebaseAuth
import Combine

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var swipeManager = SwipeManager()
    @State private var matchedProfiles: [UserProfile] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading matches...")
                } else if matchedProfiles.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Matches Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start swiping right on profiles you like in the Explore tab to find your matches here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Matches List
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(matchedProfiles, id: \.id) { profile in
                                NavigationLink {
                                    OtherProfileDetailView(profile: profile, isCurrentUser: false)
                                } label: {
                                    MatchCard(profile: profile)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Friends")
            .onAppear {
                setupManager()
            }
            .onChange(of: swipeManager.matches) { _ in
                loadMatchedProfiles()
            }
        }
    }
    
    private func setupManager() {
        if let user = authManager.user {
            swipeManager.setCurrentUser(userId: user.uid)
            loadMatchedProfiles()
        }
    }
    
    private func loadMatchedProfiles() {
        isLoading = true
        let matchedUserIds = swipeManager.getMatchedUserIds()
        
        Task {
            var profiles: [UserProfile] = []
            
            for userId in matchedUserIds {
                do {
                    if let profile = try await authManager.loadUserProfile(uid: userId) {
                        profiles.append(profile)
                    }
                } catch {
                    print("❌ Failed to load profile for user \(userId): \(error)")
                }
            }
            
            await MainActor.run {
                matchedProfiles = profiles
                isLoading = false
                print("✅ Loaded \(profiles.count) matched profiles")
            }
        }
    }
}

struct MatchCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .foregroundColor(.gray)
            
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !profile.major.isEmpty {
                    Text(profile.major)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !profile.year.isEmpty {
                    Text("Class of \(profile.year)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Message") {
                // TODO: Open chat functionality
                print("Opening chat with \(profile.name)")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
