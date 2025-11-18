//
//  ExploreView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import Combine
import FirebaseAuth

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var savedProfilesManager = SavedProfilesManager()
    @StateObject private var swipeManager = SwipeManager()
    @State private var currentProfileIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isShowingDetailView = false
    @State private var exploreProfiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var loadError: String?
    
    // Animation states
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var swipeOverlay: SwipeOverlay? = nil
    
    enum SwipeOverlay {
        case like, pass
    }
    
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
                                swipeOverlay: swipeOverlay,
                                onTap: { isShowingDetailView = true }
                            )
                            .offset(dragOffset)
                            .rotationEffect(.degrees(cardRotation))
                            .scaleEffect(cardScale)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        dragOffset = gesture.translation
                                        
                                        // Visual feedback while dragging
                                        cardRotation = Double(dragOffset.width / 20)
                                        cardScale = 1.0 - abs(dragOffset.width) / 2000
                                        
                                        // Show overlay based on drag direction
                                        if abs(dragOffset.width) > 50 {
                                            swipeOverlay = dragOffset.width > 0 ? .like : .pass
                                        } else {
                                            swipeOverlay = nil
                                        }
                                    }
                                    .onEnded { gesture in
                                        handleSwipeGesture(gesture)
                                    }
                            )
                            .animation(.easeOut, value: dragOffset)
                            
                            Spacer()
                            
                            Text("Swipe right to connect • Swipe left to pass")
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
                
                // Match Success Popup
                if swipeManager.showMatchPopup, let match = swipeManager.newMatch {
                    MatchPopup(
                        currentUser: match.0,
                        matchedUser: match.1,
                        onDismiss: {
                            swipeManager.dismissMatchPopup()
                        }
                    )
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
                setupManagers()
                if exploreProfiles.isEmpty {
                    loadExploreProfiles()
                }
            }
            .refreshable {
                loadExploreProfiles()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupManagers() {
        guard let user = authManager.user else { 
            print("⚠️ AuthManager user not available during setup")
            return 
        }
        swipeManager.setCurrentUser(userId: user.uid)
    }
    
    private func handleSwipeGesture(_ gesture: DragGesture.Value) {
        let swipeThreshold: CGFloat = 200
        let dragDistance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
        
        if dragDistance < 10 {
            // This was a tap, not a drag
            isShowingDetailView = true
            resetCard()
        } else if abs(gesture.translation.width) > swipeThreshold {
            // Swipe threshold reached
            let currentProfile = exploreProfiles[currentProfileIndex]
            
            if gesture.translation.width > 0 {
                // Swipe Right - Like
                handleSwipeRight(currentProfile)
            } else {
                // Swipe Left - Pass
                handleSwipeLeft(currentProfile)
            }
            
            // Animate card flying off
            let direction: CGFloat = gesture.translation.width > 0 ? 1 : -1
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: direction * 1000, height: gesture.translation.height)
                cardRotation = Double(direction * 30)
            }
            
            // Brief pause to show overlay, then move to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                moveToNextProfile()
            }
        } else {
            // Return to center
            resetCard()
        }
    }
    
    private func handleSwipeRight(_ profile: UserProfile) {
        guard let currentUser = getCurrentUserProfile() else { return }
        
        Task {
            await swipeManager.swipeRight(on: profile, currentUser: currentUser)
        }
    }
    
    private func handleSwipeLeft(_ profile: UserProfile) {
        Task {
            await swipeManager.swipeLeft(on: profile)
        }
    }
    
    private func getCurrentUserProfile() -> UserProfile? {
        // This should get the current user's profile
        // For now, create a basic one from auth data
        guard let user = authManager.user else { 
            print("⚠️ AuthManager user not available for getCurrentUserProfile")
            return nil 
        }
        
        return UserProfile(
            id: user.uid,
            profilePhotoURL: nil,
            name: user.displayName ?? "User",
            username: user.email?.split(separator: "@").first.map(String.init) ?? "user",
            year: "",
            major: "",
            bio: "",
            interests: [],
            clubs: [],
            personalityAnswers: ["", "", "", ""]
        )
    }
    
    private func resetCard() {
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = .zero
            cardRotation = 0
            cardScale = 1.0
            swipeOverlay = nil
        }
    }
    
    private func moveToNextProfile() {
        currentProfileIndex += 1
        resetCard()
    }
    
    private func loadExploreProfiles() {
        guard let _ = authManager.user else {
            print("⚠️ AuthManager user not available for loadExploreProfiles")
            isLoading = false
            loadError = "Authentication required"
            return
        }
        
        isLoading = true
        loadError = nil
        
        Task {
            do {
                let users = try await authManager.fetchAllUsers()
                await MainActor.run {
                    // Filter out users we've already swiped on
                    exploreProfiles = users.filter { swipeManager.shouldShowUser($0) }
                    currentProfileIndex = 0
                    isLoading = false
                    
                    if exploreProfiles.isEmpty {
                        print("📭 No new users found for explore feed")
                    } else {
                        print("📱 Loaded \(exploreProfiles.count) new users for explore feed")
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
    let swipeOverlay: ExploreView.SwipeOverlay?
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
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
            
            // Swipe Overlay
            if let overlay = swipeOverlay {
                Rectangle()
                    .fill(overlay == .like ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                VStack {
                    Image(systemName: overlay == .like ? "heart.fill" : "xmark")
                        .font(.system(size: 80))
                        .foregroundColor(overlay == .like ? .green : .red)
                    
                    Text(overlay == .like ? "CONNECT" : "PASS")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(overlay == .like ? .green : .red)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

struct MatchPopup: View {
    let currentUser: UserProfile
    let matchedUser: UserProfile
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("🎉 It's a Match! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("You and \(matchedUser.name) both want to connect!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Profile Pictures
                HStack(spacing: 30) {
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                        
                        Text("You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.pink)
                    
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                        
                        Text(matchedUser.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Send Message") {
                        // TODO: Open chat/message functionality
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Keep Exploring") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
        }
    }
}
