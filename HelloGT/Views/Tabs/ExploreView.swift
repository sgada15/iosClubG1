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
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var savedProfilesManager: SavedProfilesManager
    @StateObject private var swipeManager = SwipeManager()
    @State private var cardStack: [UserProfile] = []
    @State private var currentProfileIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isShowingDetailView = false
    @State private var exploreProfiles: [UserProfile] = []
    @State private var allProfiles: [UserProfile] = [] // Store all profiles for filtering
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectedYear: String = "All" // Year filter
    
    // Available years for filter
    private let availableYears = ["All", "2025", "2026", "2027", "2028", "2029", "2030"]
    
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
                    // Card Stack
                    VStack {
                        if !cardStack.isEmpty {
                            ZStack {
                                // Show stable 3-card stack
                                ForEach(Array(cardStack.prefix(3).enumerated()), id: \.element.id) { index, profile in
                                    // Use first card's ID instead of index to determine top card
                                    let isTopCard = !cardStack.isEmpty && profile.id == cardStack[0].id
                                    
                                    ProfileCard(
                                        profile: profile,
                                        dragOffset: isTopCard ? dragOffset : .zero,
                                        savedProfilesManager: savedProfilesManager,
                                        swipeOverlay: isTopCard ? swipeOverlay : nil,
                                        onTap: { 
                                            if isTopCard {
                                                isShowingDetailView = true 
                                            }
                                        }
                                    )
                                    .scaleEffect(isTopCard ? cardScale : (1.0 - CGFloat(index) * 0.05))
                                    .offset(
                                        x: isTopCard ? dragOffset.width : 0,
                                        y: isTopCard ? dragOffset.height : CGFloat(index) * -20
                                    )
                                    .rotationEffect(.degrees(isTopCard ? cardRotation : 0))
                                    .zIndex(Double(3 - index))
                                    .gesture(
                                        isTopCard ? 
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
                                        : nil
                                    )
                                }
                            }
                            
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
                
                // Removed Match Success Popup - now handled by AlertsView
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter by Year", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedYear == "All" ? "Year" : selectedYear)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingDetailView) {
                if !cardStack.isEmpty {
                    OtherProfileDetailView(profile: cardStack[0])
                }
            }
            .onAppear {
                setupManagers()
                // Only reload if we have no profiles at all, otherwise preserve current state
                if allProfiles.isEmpty {
                    loadExploreProfiles()
                } else {
                    // Just refresh the filtering without resetting card positions
                    refreshFilteredProfiles()
                }
            }
            .onChange(of: selectedYear) { oldValue, newValue in
                applyYearFilter()
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
        swipeManager.setNotificationManager(notificationManager)
    }
    
    private func handleSwipeGesture(_ gesture: DragGesture.Value) {
        let swipeThreshold: CGFloat = 200
        let dragDistance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
        
        print("🔍 DEBUG: handleSwipeGesture called")
        print("📊 cardStack.count: \(cardStack.count)")
        print("📊 currentProfileIndex: \(currentProfileIndex)")
        print("📊 exploreProfiles.count: \(exploreProfiles.count)")
        
        if dragDistance < 10 {
            // This was a tap, not a drag
            if !cardStack.isEmpty {
                print("👆 DEBUG: Tap detected")
                isShowingDetailView = true
            }
            resetCard()
        } else if abs(gesture.translation.width) > swipeThreshold {
            // Swipe threshold reached
            if !cardStack.isEmpty {
                let currentProfile = cardStack[0]
                print("📱 DEBUG: Swiping profile: \(currentProfile.name)")
                
                if gesture.translation.width > 0 {
                    // Swipe Right - Like
                    print("💚 DEBUG: Swipe RIGHT")
                    handleSwipeRight(currentProfile)
                } else {
                    // Swipe Left - Pass
                    print("👎 DEBUG: Swipe LEFT")
                    handleSwipeLeft(currentProfile)
                }
                
                // Animate card flying off and immediately move to next
                let direction: CGFloat = gesture.translation.width > 0 ? 1 : -1
                withAnimation(.easeOut(duration: 0.25)) {
                    dragOffset = CGSize(width: direction * 1000, height: gesture.translation.height)
                    cardRotation = Double(direction * 30)
                }
                
                // Reset drag values and move to next profile after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    print("🔄 DEBUG: About to reset and move to next")
                    // Reset FIRST to prevent new card from inheriting old values
                    dragOffset = .zero
                    cardRotation = 0
                    cardScale = 1.0
                    swipeOverlay = nil
                    
                    // THEN move to next profile (smooth slide up)
                    moveToNextProfileClean()
                }
            } else {
                print("⚠️ DEBUG: cardStack is empty, cannot swipe")
            }
        } else {
            // Return to center
            print("🔙 DEBUG: Return to center")
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
        // Remove the top card and add a new one from the remaining profiles
        if !cardStack.isEmpty {
            withAnimation(.easeOut(duration: 0.3)) {
                cardStack.removeFirst()
                
                // Add a new card from remaining profiles if available
                if currentProfileIndex < exploreProfiles.count {
                    if cardStack.count < 3 {
                        let newIndex = currentProfileIndex + cardStack.count
                        if newIndex < exploreProfiles.count {
                            cardStack.append(exploreProfiles[newIndex])
                        }
                    }
                    currentProfileIndex += 1
                }
            }
        }
        
        // Reset card state without animation conflicts
        dragOffset = .zero
        cardRotation = 0
        cardScale = 1.0
        swipeOverlay = nil
    }
    
    private func moveToNextProfileClean() {
        print("🔄 DEBUG: moveToNextProfileClean called")
        print("📊 BEFORE - cardStack.count: \(cardStack.count)")
        print("📊 BEFORE - currentProfileIndex: \(currentProfileIndex)")
        print("📊 BEFORE - exploreProfiles.count: \(exploreProfiles.count)")
        
        // Clean transition without inheriting old drag values
        if !cardStack.isEmpty {
            print("🗑️ DEBUG: Removing first card: \(cardStack[0].name)")
            
            withAnimation(.easeOut(duration: 0.3)) {
                cardStack.removeFirst()
                print("📊 AFTER removeFirst - cardStack.count: \(cardStack.count)")
                
                // Add a new card from remaining profiles if available
                if currentProfileIndex < exploreProfiles.count {
                    if cardStack.count < 3 {
                        let newIndex = currentProfileIndex + cardStack.count
                        print("🔢 DEBUG: Trying to add card at index: \(newIndex)")
                        print("📊 exploreProfiles.count: \(exploreProfiles.count)")
                        
                        if newIndex < exploreProfiles.count {
                            let newProfile = exploreProfiles[newIndex]
                            cardStack.append(newProfile)
                            print("✅ DEBUG: Added new card: \(newProfile.name)")
                        } else {
                            print("⚠️ DEBUG: newIndex (\(newIndex)) >= exploreProfiles.count (\(exploreProfiles.count))")
                        }
                    } else {
                        print("📊 DEBUG: cardStack already has 3 cards, not adding")
                    }
                    currentProfileIndex += 1
                    print("📊 DEBUG: Updated currentProfileIndex to: \(currentProfileIndex)")
                } else {
                    print("⚠️ DEBUG: currentProfileIndex (\(currentProfileIndex)) >= exploreProfiles.count (\(exploreProfiles.count))")
                }
            }
        } else {
            print("⚠️ DEBUG: cardStack is empty in moveToNextProfileClean")
        }
        
        print("📊 FINAL - cardStack.count: \(cardStack.count)")
        print("📊 FINAL - currentProfileIndex: \(currentProfileIndex)")
        print("🏁 DEBUG: moveToNextProfileClean finished")
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
                    // Store all profiles and filter out ones we've already swiped on
                    allProfiles = users.filter { swipeManager.shouldShowUser($0) }
                    
                    // Apply year filter
                    applyYearFilter()
                    
                    isLoading = false
                    
                    if exploreProfiles.isEmpty {
                        print("📭 No new users found for explore feed")
                    } else {
                        print("📱 Loaded \(exploreProfiles.count) new users for explore feed")
                        print("🃏 Card stack initialized with \(cardStack.count) cards")
                        print("📊 Starting currentProfileIndex: \(currentProfileIndex)")
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
    
    private func applyYearFilter() {
        // Filter profiles based on selected year
        if selectedYear == "All" {
            exploreProfiles = allProfiles
        } else {
            exploreProfiles = allProfiles.filter { $0.year == selectedYear }
        }
        
        // Reset card stack with filtered profiles (only when filter changes)
        if !exploreProfiles.isEmpty {
            cardStack = [exploreProfiles[0]]
            currentProfileIndex = 1
            
            // Add cards 2 and 3 if available
            for i in 1..<min(3, exploreProfiles.count) {
                cardStack.append(exploreProfiles[i])
                currentProfileIndex += 1
            }
        } else {
            cardStack = []
            currentProfileIndex = 0
        }
        
        print("🔍 Applied year filter: \(selectedYear)")
        print("📊 Filtered profiles count: \(exploreProfiles.count)")
    }
    
    private func refreshFilteredProfiles() {
        // Re-filter allProfiles based on swipe history (users we haven't swiped on)
        allProfiles = allProfiles.filter { swipeManager.shouldShowUser($0) }
        
        // Apply year filter without resetting card positions
        if selectedYear == "All" {
            exploreProfiles = allProfiles
        } else {
            exploreProfiles = allProfiles.filter { $0.year == selectedYear }
        }
        
        // Only update card stack if it's empty or contains profiles we've now swiped on
        if cardStack.isEmpty || !cardStack.allSatisfy({ profile in exploreProfiles.contains { $0.id == profile.id } }) {
            resetCardStackToCurrentPosition()
        }
        
        print("🔄 Refreshed filtered profiles: \(exploreProfiles.count) available")
        print("📚 Current card stack: \(cardStack.count) cards")
    }
    
    private func resetCardStackToCurrentPosition() {
        // Reset card stack with current position preserved
        if !exploreProfiles.isEmpty {
            // Find a valid starting position
            let startIndex = max(0, min(currentProfileIndex, exploreProfiles.count - 1))
            cardStack = []
            currentProfileIndex = startIndex
            
            // Add up to 3 cards starting from current position
            for i in 0..<min(3, exploreProfiles.count - startIndex) {
                if startIndex + i < exploreProfiles.count {
                    cardStack.append(exploreProfiles[startIndex + i])
                }
            }
            
            print("🃏 Reset card stack starting at index \(startIndex)")
        } else {
            cardStack = []
            currentProfileIndex = 0
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
            // Main Content - Instagram Style
            VStack(spacing: 20) {
                // Save Button (top right corner)
                HStack {
                    Spacer()
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Profile Content (Center-aligned Instagram style)
                VStack(spacing: 16) {
                    // Profile Photo
                    AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    
                    // Name and Major (Center-aligned)
                    VStack(spacing: 6) {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(profile.major)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Personality Quote with Label (Instagram caption style)
                    if !profile.personalityAnswers.isEmpty && !profile.personalityAnswers[0].isEmpty {
                        HStack {
                            Text("Free time:")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("\"\(profile.personalityAnswers[0])\"")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
                    
                    // Interests with Label
                    if !profile.interests.isEmpty {
                        HStack {
                            Text("Interests:")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            let displayInterests = Array(profile.interests.prefix(3))
                            Text(displayInterests.joined(separator: " • "))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
                    
                    // Clubs with Label
                    if !profile.clubs.isEmpty {
                        HStack {
                            Text("Clubs:")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            let displayClubs = Array(profile.clubs.prefix(2))
                            Text(displayClubs.joined(separator: " • "))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
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
