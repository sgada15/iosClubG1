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
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var swipeManager = SwipeManager()
    @State private var matchedProfiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var showAlerts = false
    
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
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 20) {
                            ForEach(matchedProfiles, id: \.id) { profile in
                                MatchCard(
                                    profile: profile,
                                    onUnfriend: {
                                        Task {
                                            await unfriend(userId: profile.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAlerts = true
                    } label: {
                        HStack {
                            Image(systemName: "bell")
                            if notificationManager.unreadCount > 0 {
                                Text("\(notificationManager.unreadCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAlerts) {
                AlertsView()
                    .environmentObject(authManager)
                    .environmentObject(notificationManager)
            }
            .onAppear {
                setupManager()
            }
            .onChange(of: swipeManager.matches) { oldValue, newValue in
                loadMatchedProfiles()
            }
            .onChange(of: notificationManager.matchNotifications) { oldValue, newValue in
                // Reload when a notification is acknowledged (opened)
                // This will trigger when matchNotifications changes (e.g., when isRead is set to true)
                loadMatchedProfiles()
            }
            .refreshable {
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
        
        // Only get matches that have been acknowledged (notification opened)
        let allMatchedUserIds = swipeManager.getMatchedUserIds()
        let acknowledgedMatchIds = notificationManager.acknowledgedMatchIds
        
        // Filter to only include matches that have been acknowledged
        let acknowledgedMatches = swipeManager.matches.filter { match in
            notificationManager.isMatchAcknowledged(matchId: match.id)
        }
        
        // Get user IDs from acknowledged matches only
        guard let currentUserId = authManager.user?.uid else {
            isLoading = false
            return
        }
        
        let acknowledgedUserIds = acknowledgedMatches.flatMap { match in
            [match.user1Id, match.user2Id].filter { $0 != currentUserId }
        }
        
        print("🔄 Loading matched profiles...")
        print("📊 Total matches in swipeManager: \(swipeManager.matches.count)")
        print("📊 Acknowledged matches: \(acknowledgedMatches.count)")
        print("👥 Loading profiles for \(acknowledgedUserIds.count) acknowledged matches")
        print("👥 User IDs to load: \(acknowledgedUserIds)")
        
        Task {
            var profiles: [UserProfile] = []
            
            for userId in acknowledgedUserIds {
                do {
                    if let profile = try await authManager.loadUserProfile(uid: userId) {
                        profiles.append(profile)
                        print("✅ Loaded profile: \(profile.name) (ID: \(profile.id))")
                    } else {
                        print("⚠️ No profile found for user ID: \(userId)")
                    }
                } catch {
                    print("❌ Failed to load profile for user \(userId): \(error)")
                }
            }
            
            await MainActor.run {
                // Ensure we're not including any profiles that shouldn't be there
                // Filter out any profiles that don't have a corresponding acknowledged match
                let validUserIds = Set(acknowledgedUserIds)
                matchedProfiles = profiles.filter { validUserIds.contains($0.id) }
                isLoading = false
                print("✅ Loaded \(matchedProfiles.count) acknowledged matched profiles total")
                print("📋 Final profiles: \(matchedProfiles.map { $0.name })")
            }
        }
    }
    
    private func unfriend(userId: String) async {
        print("🔄 Starting unfriend process for user: \(userId)")
        
        // Immediately remove from UI for better UX
        await MainActor.run {
            matchedProfiles.removeAll { $0.id == userId }
            print("🗑️ Removed \(userId) from UI immediately")
        }
        
        do {
            try await swipeManager.unfriend(userId: userId)
            print("✅ Unfriend completed in Firebase")
            
            // Don't reload immediately - the Firestore listener will update swipeManager.matches
            // and the onChange handler will trigger loadMatchedProfiles automatically
            // This prevents the profile from reappearing if the listener hasn't fired yet
        } catch {
            print("❌ Failed to unfriend user \(userId): \(error)")
            // If deletion failed, reload to restore the profile
            await loadMatchedProfiles()
        }
    }
}

struct MatchCard: View {
    let profile: UserProfile
    let onUnfriend: () -> Void
    
    @State private var showUnfriendAlert = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                OtherProfileDetailView(profile: profile, isCurrentUser: false)
            } label: {
                VStack(spacing: 16) {
                    // Bigger profile image
                    AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(spacing: 6) {
                        Text(profile.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Always reserve space for major (but show empty if not available)
                        Text(profile.major)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(minHeight: 20) // Reserve space even if empty
                        
                        // Always reserve space for year (but show empty if not available)
                        Text(profile.year.isEmpty ? "" : "Class of \(profile.year)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(minHeight: 16) // Reserve space even if empty
                    }
                    .frame(height: 70) // Fixed height for text area
                    
                    Button("Message") {
                        // TODO: Open chat functionality
                        print("Opening chat with \(profile.name)")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .frame(minHeight: 220) // Taller minimum height
                .frame(maxWidth: .infinity) // Take full width available
                .padding(20) // More generous padding
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // Delete button in top-right corner (outside NavigationLink)
            Button {
                showUnfriendAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .padding(8)
            .zIndex(1) // Ensure button is above NavigationLink
        }
        .alert("Unfriend \(profile.name)?", isPresented: $showUnfriendAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unfriend", role: .destructive) {
                onUnfriend()
            }
        } message: {
            Text("This will remove \(profile.name) from your friends list. They will also lose you as a friend.")
        }
    }
}
