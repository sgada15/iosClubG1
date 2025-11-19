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
                                NavigationLink {
                                    OtherProfileDetailView(profile: profile, isCurrentUser: false)
                                } label: {
                                    MatchCard(profile: profile)
                                }
                                .buttonStyle(.plain)
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
            .onChange(of: swipeManager.matches) { _ in
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
        let matchedUserIds = swipeManager.getMatchedUserIds()
        
        print("🔄 Loading matched profiles for user IDs: \(matchedUserIds)")
        
        Task {
            var profiles: [UserProfile] = []
            
            for userId in matchedUserIds {
                do {
                    if let profile = try await authManager.loadUserProfile(uid: userId) {
                        profiles.append(profile)
                        print("✅ Loaded profile: \(profile.name) - Major: '\(profile.major)' Year: '\(profile.year)'")
                    } else {
                        print("⚠️ No profile found for user ID: \(userId)")
                    }
                } catch {
                    print("❌ Failed to load profile for user \(userId): \(error)")
                }
            }
            
            await MainActor.run {
                matchedProfiles = profiles
                isLoading = false
                print("✅ Loaded \(profiles.count) matched profiles total")
            }
        }
    }
}

struct MatchCard: View {
    let profile: UserProfile
    
    var body: some View {
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
}
