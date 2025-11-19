//
//  SwipeManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

class SwipeManager: ObservableObject {
    @Published var matches: [Match] = []
    @Published var showMatchPopup = false
    @Published var newMatch: (UserProfile, UserProfile)? = nil
    
    private let db = Firestore.firestore()
    private var currentUserId: String = ""
    private var userSwipeData = UserSwipeData()
    private var isLoadingSwipeData = false // Prevent concurrent loads
    
    // Firestore listeners
    private var matchesListeners: [ListenerRegistration] = []
    
    // Reference to notification manager
    weak var notificationManager: NotificationManager?
    
    init() {
        // Will be set when user logs in
    }
    
    func setCurrentUser(userId: String) {
        // Only reload if user changed
        guard self.currentUserId != userId else {
            print("ℹ️ User already set to \(userId), skipping reload")
            return
        }
        
        // Remove old listeners if user changed
        matchesListeners.forEach { $0.remove() }
        matchesListeners.removeAll()
        
        self.currentUserId = userId
        loadUserSwipeData()
        loadMatches()
        setupMatchesListener()
    }
    
    deinit {
        matchesListeners.forEach { $0.remove() }
    }
    
    func setNotificationManager(_ manager: NotificationManager) {
        self.notificationManager = manager
        
        // If matches are already loaded, check for missing notifications
        if !matches.isEmpty {
            Task {
                await createMissingNotifications(for: matches)
            }
        }
    }
    
    // MARK: - Swipe Actions
    
    func swipeRight(on targetUser: UserProfile, currentUser: UserProfile) async {
        guard !currentUserId.isEmpty else { return }
        
        // Prevent duplicate swipes
        if userSwipeData.rightSwipes.contains(targetUser.id) {
            print("⚠️ Already swiped right on \(targetUser.name)")
            return
        }
        
        // Add to right swipes
        userSwipeData.rightSwipes.append(targetUser.id)
        
        // Save swipe decision
        try? await saveSwipeDecision(targetUserId: targetUser.id, decision: .like)
        
        // Check if target user has already swiped right on current user
        let hasMatch = try? await checkForMatch(targetUserId: targetUser.id)
        
        if hasMatch == true {
            // Create match!
            let match = Match(user1Id: currentUserId, user2Id: targetUser.id)
            try? await createMatch(match)
            
            // Add to notification system instead of showing popup immediately
            await MainActor.run {
                matches.append(match)
                notificationManager?.addMatchNotification(
                    match: match,
                    currentUserId: currentUserId,
                    matchedUserName: targetUser.name
                )
            }
            
            print("🎉 MATCH with \(targetUser.name)! Added to notifications.")
        } else {
            print("💚 Swiped right on \(targetUser.name) - waiting for their swipe")
        }
        
        // Save updated swipe data
        try? await saveUserSwipeData()
    }
    
    func swipeLeft(on targetUser: UserProfile) async {
        guard !currentUserId.isEmpty else { return }
        
        // Prevent duplicate swipes
        if userSwipeData.leftSwipes.contains(targetUser.id) {
            print("⚠️ Already swiped left on \(targetUser.name)")
            return
        }
        
        // Add to left swipes
        userSwipeData.leftSwipes.append(targetUser.id)
        
        // Save swipe decision
        try? await saveSwipeDecision(targetUserId: targetUser.id, decision: .pass)
        
        print("👎 Passed on \(targetUser.name)")
        
        // Save updated swipe data
        try? await saveUserSwipeData()
    }
    
    // MARK: - Filtering
    
    func shouldShowUser(_ user: UserProfile) -> Bool {
        // Don't show users we've already swiped on
        return !userSwipeData.rightSwipes.contains(user.id) && 
               !userSwipeData.leftSwipes.contains(user.id)
    }
    
    // MARK: - Firebase Operations
    
    private func saveSwipeDecision(targetUserId: String, decision: SwipeType) async throws {
        let swipeDecision = SwipeDecision(
            userId: currentUserId,
            targetUserId: targetUserId,
            decision: decision,
            timestamp: Date()
        )
        
        let data = try JSONEncoder().encode(swipeDecision)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await db.collection("swipeDecisions").document().setData(dict)
    }
    
    private func checkForMatch(targetUserId: String) async throws -> Bool {
        // Check if target user has swiped right on current user
        let query = db.collection("swipeDecisions")
            .whereField("userId", isEqualTo: targetUserId)
            .whereField("targetUserId", isEqualTo: currentUserId)
            .whereField("decision", isEqualTo: "right")
        
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    private func createMatch(_ match: Match) async throws {
        let data = try JSONEncoder().encode(match)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await db.collection("matches").document(match.id).setData(dict)
        
        // Update both users' match lists
        userSwipeData.matches.append(match.id)
        
        // Also update the other user's match list
        try await db.collection("userSwipeData").document(match.user2Id).updateData([
            "matches": FieldValue.arrayUnion([match.id])
        ])
    }
    
    private func saveUserSwipeData() async throws {
        let data = try JSONEncoder().encode(userSwipeData)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await db.collection("userSwipeData").document(currentUserId).setData(dict, merge: true)
    }
    
    private func loadUserSwipeData() {
        // Prevent concurrent loads
        guard !isLoadingSwipeData else {
            print("⚠️ Already loading swipe data, skipping duplicate call")
            return
        }
        
        Task {
            await MainActor.run {
                self.isLoadingSwipeData = true
            }
            
            defer {
                Task { @MainActor in
                    self.isLoadingSwipeData = false
                }
            }
            
            do {
                let document = try await db.collection("userSwipeData").document(currentUserId).getDocument()
                
                var loadedData: UserSwipeData
                
                if document.exists, let data = document.data() {
                    // Safely extract arrays from Firestore data
                    // Firestore stores arrays directly, so we can decode them safely
                    loadedData = UserSwipeData()
                    loadedData.rightSwipes = data["rightSwipes"] as? [String] ?? []
                    loadedData.leftSwipes = data["leftSwipes"] as? [String] ?? []
                    loadedData.matches = data["matches"] as? [String] ?? []
                } else {
                    loadedData = UserSwipeData() // Empty data for new user
                }
                
                // Update on main thread to avoid thread safety issues
                await MainActor.run {
                    self.userSwipeData = loadedData
                    print("✅ Loaded swipe data: \(self.userSwipeData.rightSwipes.count) right swipes, \(self.userSwipeData.leftSwipes.count) left swipes")
                }
            } catch {
                print("❌ Failed to load user swipe data: \(error)")
                await MainActor.run {
                    self.userSwipeData = UserSwipeData()
                }
            }
        }
    }
    
    private func loadMatches() {
        Task {
            do {
                let query = db.collection("matches")
                    .whereField("user1Id", isEqualTo: currentUserId)
                
                let query2 = db.collection("matches")
                    .whereField("user2Id", isEqualTo: currentUserId)
                
                let snapshot1 = try await query.getDocuments()
                let snapshot2 = try await query2.getDocuments()
                
                var loadedMatches: [Match] = []
                
                for document in snapshot1.documents + snapshot2.documents {
                    let data = try JSONSerialization.data(withJSONObject: document.data())
                    let match = try JSONDecoder().decode(Match.self, from: data)
                    loadedMatches.append(match)
                }
                
                await MainActor.run {
                    matches = loadedMatches
                    print("✅ Loaded \(matches.count) matches")
                    
                    // Check for matches that don't have notifications yet
                    Task {
                        await createMissingNotifications(for: loadedMatches)
                    }
                }
            } catch {
                print("❌ Failed to load matches: \(error)")
            }
        }
    }
    
    // MARK: - Real-time Match Detection
    
    /// Sets up a Firestore listener to detect new matches in real-time
    private func setupMatchesListener() {
        guard !currentUserId.isEmpty else { return }
        
        // Listen for matches where current user is user1
        let query1 = db.collection("matches")
            .whereField("user1Id", isEqualTo: currentUserId)
        
        // Listen for matches where current user is user2
        let query2 = db.collection("matches")
            .whereField("user2Id", isEqualTo: currentUserId)
        
        // Set up listener for query1
        let listener1 = query1.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error listening to matches (query1): \(error)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            // Process new matches
            for documentChange in snapshot.documentChanges {
                if documentChange.type == .added {
                    self.handleNewMatch(document: documentChange.document)
                }
            }
        }
        
        // Set up listener for query2
        let listener2 = query2.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error listening to matches (query2): \(error)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            // Process new matches
            for documentChange in snapshot.documentChanges {
                if documentChange.type == .added {
                    self.handleNewMatch(document: documentChange.document)
                }
            }
        }
        
        // Store both listeners
        matchesListeners = [listener1, listener2]
        
        print("👂 Set up real-time match listeners for user: \(currentUserId)")
    }
    
    /// Handles a new match detected by the listener
    private func handleNewMatch(document: QueryDocumentSnapshot) {
        Task {
            do {
                let data = try JSONSerialization.data(withJSONObject: document.data())
                let match = try JSONDecoder().decode(Match.self, from: data)
                
                // Check if this match is already in our matches array (on main thread)
                let isNewMatch = await MainActor.run {
                    let exists = matches.contains(where: { $0.id == match.id })
                    if !exists {
                        matches.append(match)
                    }
                    return !exists
                }
                
                if isNewMatch {
                    print("🔔 New match detected in real-time: \(match.id)")
                    
                    // Create notification for this new match
                    await createMissingNotifications(for: [match])
                } else {
                    print("ℹ️ Match \(match.id) already exists, skipping notification")
                }
            } catch {
                print("❌ Failed to decode new match: \(error)")
            }
        }
    }
    
    // MARK: - Notification Creation for Existing Matches
    
    /// Creates notifications for matches that don't have them yet
    /// This ensures that if User A swiped first, they get notified when User B creates the match
    private func createMissingNotifications(for matches: [Match]) async {
        guard let notificationManager = notificationManager else {
            print("⚠️ NotificationManager not set, cannot create notifications")
            return
        }
        
        for match in matches {
            // Check if notification already exists for this match
            let hasNotification = notificationManager.matchNotifications.contains(where: { $0.matchId == match.id })
            
            if !hasNotification {
                // Get the matched user's ID (the other user in the match)
                let matchedUserId = match.user1Id == currentUserId ? match.user2Id : match.user1Id
                
                // Load the matched user's profile to get their name
                if let matchedProfile = try? await loadUserProfile(userId: matchedUserId) {
                    await MainActor.run {
                        notificationManager.addMatchNotification(
                            match: match,
                            currentUserId: currentUserId,
                            matchedUserName: matchedProfile.name
                        )
                        print("🔔 Created missing notification for match with \(matchedProfile.name)")
                    }
                } else {
                    print("⚠️ Could not load profile for user \(matchedUserId) to create notification")
                }
            }
        }
    }
    
    // MARK: - Load User Profile
    
    /// Loads a user profile from Firebase
    private func loadUserProfile(userId: String) async throws -> UserProfile? {
        let docRef = db.collection("users").document(userId)
        let document = try await docRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        // Convert Firestore data to UserProfile
        // Handle the profilePhotoURL which might be missing
        var profileData = data
        if profileData["profilePhotoURL"] == nil {
            profileData["profilePhotoURL"] = NSNull()
        }
        
        // Ensure all required fields exist
        guard let name = profileData["name"] as? String,
              let username = profileData["username"] as? String,
              let year = profileData["year"] as? String,
              let major = profileData["major"] as? String,
              let bio = profileData["bio"] as? String,
              let interests = profileData["interests"] as? [String],
              let clubs = profileData["clubs"] as? [String],
              let personalityAnswers = profileData["personalityAnswers"] as? [String] else {
            print("⚠️ Missing required fields in profile data for user \(userId)")
            return nil
        }
        
        let profilePhotoURL = profileData["profilePhotoURL"] as? String
        
        return UserProfile(
            id: userId,
            profilePhotoURL: profilePhotoURL,
            name: name,
            username: username,
            year: year,
            major: major,
            bio: bio,
            interests: interests,
            clubs: clubs,
            personalityAnswers: personalityAnswers
        )
    }
    
    // MARK: - Helper Functions
    
    func getMatchedUserIds() -> [String] {
        return matches.flatMap { match in
            [match.user1Id, match.user2Id].filter { $0 != currentUserId }
        }
    }
    
    @MainActor
    func dismissMatchPopup() {
        showMatchPopup = false
        newMatch = nil
    }
}