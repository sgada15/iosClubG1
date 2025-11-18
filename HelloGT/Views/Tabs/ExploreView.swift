//
//  ExploreView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var savedProfilesManager = SavedProfilesManager()
    @State private var currentProfileIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isShowingDetailView = false
    @State private var exploreProfiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                if isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding Georgia Tech students...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = loadError {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Connection Error")
                            .font(.title2)
                            .bold()
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            loadExploreProfiles()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Main Content
                    VStack {
                        if currentProfileIndex < exploreProfiles.count {
                            ProfileCard(
                                profile: exploreProfiles[currentProfileIndex],
                                dragOffset: dragOffset,
                                savedProfilesManager: savedProfilesManager,
                                onTap: { isShowingDetailView = true }
                            )
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width / 10)))
                            .scaleEffect(1.0 - abs(dragOffset.width) / 1000)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        dragOffset = gesture.translation
                                    }
                                    .onEnded { gesture in
                                        let dragDistance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
                                        
                                        if dragDistance < 10 {
                                            // This was a tap, not a drag
                                            isShowingDetailView = true
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                dragOffset = .zero
                                            }
                                        } else if abs(gesture.translation.width) > 100 {
                                            // Swipe threshold reached
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                dragOffset = CGSize(
                                                    width: gesture.translation.width > 0 ? 1000 : -1000,
                                                    height: gesture.translation.height
                                                )
                                            }
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                moveToNextProfile()
                                            }
                                        } else {
                                            // Return to center
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )
                            .animation(.easeOut, value: dragOffset)
                            
                            Spacer()
                            
                            Text("Swipe left or right to see more profiles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            
                            Text("Tap to view full profile")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 20)
                        } else {
                            // No more profiles
                            VStack(spacing: 16) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                
                                Text("No more profiles")
                                    .font(.title2)
                                    .bold()
                                
                                Text(exploreProfiles.isEmpty ? "No other Georgia Tech students found. Be the first to create a profile!" : "Check back later for more Georgia Tech students!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Refresh") {
                                    loadExploreProfiles()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingDetailView) {
                if currentProfileIndex < exploreProfiles.count {
                    OtherProfileDetailView(profile: exploreProfiles[currentProfileIndex])
                }
            }
            .onAppear {
                if exploreProfiles.isEmpty {
                    loadExploreProfiles()
                }
            }
            .refreshable {
                loadExploreProfiles()
            }
        }
    }
    
    private func moveToNextProfile() {
        currentProfileIndex += 1
        dragOffset = .zero
    }
    
    private func loadExploreProfiles() {
        isLoading = true
        loadError = nil
        
        Task {
            do {
                let users = try await authManager.fetchAllUsers()
                await MainActor.run {
                    exploreProfiles = users
                    currentProfileIndex = 0
                    isLoading = false
                    
                    if users.isEmpty {
                        print("📭 No other users found for explore feed")
                    } else {
                        print("📱 Loaded \(users.count) users for explore feed")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadError = "Failed to load profiles: \(error.localizedDescription)"
                    print("❌ Failed to load explore profiles: \(error)")
                }
            }
        }
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    let dragOffset: CGSize
    let savedProfilesManager: SavedProfilesManager
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Profile picture and save button
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        .shadow(radius: 8)
                    
                    VStack(spacing: 4) {
                        Text(profile.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("\(profile.major) • \(profile.year)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button(action: {
                        if savedProfilesManager.isProfileSaved(profile) {
                            savedProfilesManager.unsaveProfile(profile)
                        } else {
                            savedProfilesManager.saveProfile(profile)
                        }
                    }) {
                        Image(systemName: savedProfilesManager.isProfileSaved(profile) ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                            .foregroundColor(savedProfilesManager.isProfileSaved(profile) ? .accentColor : .secondary)
                            .padding(12)
                            .background(Circle().fill(Color(.systemGray6)))
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
            
            // About section
            if !profile.bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(profile.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
            }
            
            // Quick interests preview
            if !profile.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(profile.interests.prefix(3).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if profile.interests.count > 3 {
                        Text("and \(profile.interests.count - 3) more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}
