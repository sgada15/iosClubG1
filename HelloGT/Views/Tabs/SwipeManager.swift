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
    
    init() {
        // Will be set when user logs in
    }
    
    func setCurrentUser(userId: String) {
        self.currentUserId = userId
        loadUserSwipeData()
        loadMatches()
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
            
            // Show match popup
            await MainActor.run {
                newMatch = (currentUser, targetUser)
                showMatchPopup = true
                matches.append(match)
            }
            
            print("🎉 MATCH with \(targetUser.name)!")
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
        Task {
            do {
                let document = try await db.collection("userSwipeData").document(currentUserId).getDocument()
                
                if document.exists, let data = document.data() {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    userSwipeData = try JSONDecoder().decode(UserSwipeData.self, from: jsonData)
                } else {
                    userSwipeData = UserSwipeData() // Empty data for new user
                }
                
                print("✅ Loaded swipe data: \(userSwipeData.rightSwipes.count) right swipes, \(userSwipeData.leftSwipes.count) left swipes")
            } catch {
                print("❌ Failed to load user swipe data: \(error)")
                userSwipeData = UserSwipeData()
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
                }
            } catch {
                print("❌ Failed to load matches: \(error)")
            }
        }
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