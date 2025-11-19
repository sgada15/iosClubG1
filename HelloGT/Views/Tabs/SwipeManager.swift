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
            // Create match with sorted user IDs to ensure consistency
            // This ensures the match document has the same structure regardless of who creates it
            let sortedIds = [currentUserId, targetUser.id].sorted()
            let match = Match(user1Id: sortedIds[0], user2Id: sortedIds[1])
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
        
        print("💾 Creating match document: \(match.id)")
        print("   user1Id: \(match.user1Id)")
        print("   user2Id: \(match.user2Id)")
        print("   currentUserId: \(currentUserId)")
        
        // Use merge to avoid overwriting if match already exists
        try await db.collection("matches").document(match.id).setData(dict, merge: false)
        
        print("✅ Match document created/updated: \(match.id)")
        
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
                print("🔍 Loading matches for user: \(currentUserId)")
                
                let query = db.collection("matches")
                    .whereField("user1Id", isEqualTo: currentUserId)
                
                let query2 = db.collection("matches")
                    .whereField("user2Id", isEqualTo: currentUserId)
                
                let snapshot1 = try await query.getDocuments()
                let snapshot2 = try await query2.getDocuments()
                
                print("📊 Query 1 (user1Id): Found \(snapshot1.documents.count) matches")
                print("📊 Query 2 (user2Id): Found \(snapshot2.documents.count) matches")
                
                var loadedMatches: [Match] = []
                var seenMatchIds = Set<String>()
                
                // Process query1 results
                for document in snapshot1.documents {
                    let data = try JSONSerialization.data(withJSONObject: document.data())
                    let match = try JSONDecoder().decode(Match.self, from: data)
                    if !seenMatchIds.contains(match.id) {
                        loadedMatches.append(match)
                        seenMatchIds.insert(match.id)
                        print("  ✅ Match: \(match.id) - user1Id: \(match.user1Id), user2Id: \(match.user2Id)")
                    }
                }
                
                // Process query2 results
                for document in snapshot2.documents {
                    let data = try JSONSerialization.data(withJSONObject: document.data())
                    let match = try JSONDecoder().decode(Match.self, from: data)
                    if !seenMatchIds.contains(match.id) {
                        loadedMatches.append(match)
                        seenMatchIds.insert(match.id)
                        print("  ✅ Match: \(match.id) - user1Id: \(match.user1Id), user2Id: \(match.user2Id)")
                    }
                }
                
                await MainActor.run {
                    matches = loadedMatches
                    print("✅ Loaded \(matches.count) total unique matches for user \(currentUserId)")
                    
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
            
            // Process match changes (added, removed)
            for documentChange in snapshot.documentChanges {
                switch documentChange.type {
                case .added:
                    self.handleNewMatch(document: documentChange.document)
                case .removed:
                    self.handleRemovedMatch(document: documentChange.document)
                default:
                    break
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
            
            // Process match changes (added, removed)
            for documentChange in snapshot.documentChanges {
                switch documentChange.type {
                case .added:
                    self.handleNewMatch(document: documentChange.document)
                case .removed:
                    self.handleRemovedMatch(document: documentChange.document)
                default:
                    break
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
    
    /// Handles a removed match detected by the listener
    private func handleRemovedMatch(document: QueryDocumentSnapshot) {
        Task {
            let matchId = document.documentID
            
            await MainActor.run {
                // Remove match from local array
                matches.removeAll { $0.id == matchId }
                print("🗑️ Match removed in real-time: \(matchId)")
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
    
    // MARK: - Unfriend Functionality
    
    /// Unfriends a user by deleting the match from both users
    func unfriend(userId: String) async throws {
        guard !currentUserId.isEmpty else {
            throw NSError(domain: "SwipeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user set"])
        }
        
        print("🗑️ Attempting to unfriend user: \(userId)")
        print("   Current user: \(currentUserId)")
        print("   Current matches count: \(matches.count)")
        
        // Find the match between current user and the friend
        // Try to find in local matches first
        var match: Match? = matches.first(where: { match in
            (match.user1Id == currentUserId && match.user2Id == userId) ||
            (match.user1Id == userId && match.user2Id == currentUserId)
        })
        
        // If not found locally, construct the match ID and try to delete it anyway
        // Match IDs are always sorted, so we can construct it
        if match == nil {
            let sortedIds = [currentUserId, userId].sorted()
            let matchId = "\(sortedIds[0])_\(sortedIds[1])"
            print("⚠️ Match not found in local array, trying to delete by ID: \(matchId)")
            
            // Try to delete the match document directly
            do {
                try await db.collection("matches").document(matchId).delete()
                print("✅ Successfully deleted match document: \(matchId)")
                
                // Remove from local matches array if it exists
                await MainActor.run {
                    matches.removeAll { $0.id == matchId }
                    userSwipeData.matches.removeAll { $0 == matchId }
                }
                
                // Save updated swipe data
                try? await saveUserSwipeData()
                
                print("✅ Successfully unfriended user \(userId)")
                return
            } catch {
                print("❌ Failed to delete match document: \(error)")
                throw error
            }
        }
        
        guard let foundMatch = match else {
            print("⚠️ No match found between \(currentUserId) and \(userId)")
            throw NSError(domain: "SwipeManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No match found"])
        }
        
        print("🗑️ Found match: \(foundMatch.id)")
        print("   user1Id: \(foundMatch.user1Id)")
        print("   user2Id: \(foundMatch.user2Id)")
        
        // Delete the match document from Firebase
        do {
            try await db.collection("matches").document(foundMatch.id).delete()
            print("✅ Deleted match document from Firebase: \(foundMatch.id)")
        } catch {
            print("❌ Error deleting match document: \(error)")
            throw error
        }
        
        // Remove from local matches array
        await MainActor.run {
            let beforeCount = matches.count
            matches.removeAll { $0.id == foundMatch.id }
            let afterCount = matches.count
            print("📊 Matches array: \(beforeCount) -> \(afterCount)")
        }
        
        // Remove from userSwipeData matches array
        await MainActor.run {
            userSwipeData.matches.removeAll { $0 == foundMatch.id }
        }
        
        // Save updated swipe data
        do {
            try await saveUserSwipeData()
            print("✅ Saved updated swipe data")
        } catch {
            print("⚠️ Failed to save swipe data: \(error)")
        }
        
        print("✅ Successfully unfriended user \(userId)")
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