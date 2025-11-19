//
//  FriendsManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FriendsManager: ObservableObject {
    @Published var userFriends: [UserProfile] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?
    
    deinit {
        friendsListener?.remove()
    }
    
    // MARK: - Friends Management
    
    /// Add a friend relationship
    func addFriend(currentUserId: String, friendProfile: UserProfile) async {
        print("👥 Adding friend: \(friendProfile.name) (ID: \(friendProfile.id)) for user \(currentUserId)")
        do {
            // Add friend to current user's friends list
            let userFriendsRef = db.collection("userFriends").document(currentUserId)
            try await userFriendsRef.setData([
                "friendIds": FieldValue.arrayUnion([friendProfile.id]),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            
            print("✅ Added to current user's friends list")
            
            // Add current user to friend's friends list (mutual friendship)
            let friendFriendsRef = db.collection("userFriends").document(friendProfile.id)
            try await friendFriendsRef.setData([
                "friendIds": FieldValue.arrayUnion([currentUserId]),
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            
            print("✅ Added to friend's friends list (mutual)")
            
            // Update local state
            if !userFriends.contains(where: { $0.id == friendProfile.id }) {
                userFriends.append(friendProfile)
                print("✅ Added to local friends list: \(userFriends.count) total friends")
            }
            
            print("✅ Added friend: \(friendProfile.name)")
            
        } catch {
            print("❌ Failed to add friend: \(error)")
            self.error = "Failed to add friend: \(error.localizedDescription)"
        }
    }
    
    /// Remove a friend relationship
    func removeFriend(currentUserId: String, friendId: String) async {
        do {
            // Remove friend from current user's friends list
            let userFriendsRef = db.collection("userFriends").document(currentUserId)
            try await userFriendsRef.updateData([
                "friendIds": FieldValue.arrayRemove([friendId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            // Remove current user from friend's friends list
            let friendFriendsRef = db.collection("userFriends").document(friendId)
            try await friendFriendsRef.updateData([
                "friendIds": FieldValue.arrayRemove([currentUserId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            // Update local state
            userFriends.removeAll { $0.id == friendId }
            
            print("✅ Removed friend with ID: \(friendId)")
            
        } catch {
            print("❌ Failed to remove friend: \(error)")
            self.error = "Failed to remove friend: \(error.localizedDescription)"
        }
    }
    
    /// Check if a user is a friend
    func isFriend(userId: String) -> Bool {
        return userFriends.contains { $0.id == userId }
    }
    
    // MARK: - Load Friends
    
    /// Load friends for a user from existing matches system
    func loadFriends(for userId: String, authManager: AuthenticationManager) async {
        print("👥 === LOADING FRIENDS FROM MATCHES ===")
        print("👥 User ID: \(userId)")
        isLoading = true
        
        do {
            var friendIds: [String] = []
            
            // Check Method 1: matches/{userId}/friends/{friendId} (nested structure)
            print("👥 🔍 Checking nested structure: matches/\(userId)/friends/")
            let nestedMatchesSnapshot = try await db.collection("matches").document(userId)
                .collection("friends").getDocuments()
            print("👥 📊 Nested structure has \(nestedMatchesSnapshot.documents.count) friend documents")
            
            if !nestedMatchesSnapshot.documents.isEmpty {
                let nestedFriendIds = nestedMatchesSnapshot.documents.map { $0.documentID }
                print("👥 ✅ Found friends in nested structure: \(nestedFriendIds)")
                friendIds.append(contentsOf: nestedFriendIds)
            }
            
            // Check Method 2: matches/{matchId} (flat structure) 
            print("👥 🔍 Checking flat structure: matches/ (where user1Id or user2Id = current user)")
            let flatMatchesSnapshot = try await db.collection("matches").getDocuments()
            print("👥 📊 Flat structure has \(flatMatchesSnapshot.documents.count) total match documents")
            
            var flatFriendIds: [String] = []
            for doc in flatMatchesSnapshot.documents {
                let data = doc.data()
                if let user1Id = data["user1Id"] as? String,
                   let user2Id = data["user2Id"] as? String {
                    
                    if user1Id == userId {
                        flatFriendIds.append(user2Id)
                        print("👥 📄 Found match: current user (\(userId)) matched with \(user2Id)")
                    } else if user2Id == userId {
                        flatFriendIds.append(user1Id)
                        print("👥 📄 Found match: \(user1Id) matched with current user (\(userId))")
                    }
                }
            }
            
            if !flatFriendIds.isEmpty {
                print("👥 ✅ Found friends in flat structure: \(flatFriendIds)")
                friendIds.append(contentsOf: flatFriendIds)
            }
            
            // Remove duplicates
            friendIds = Array(Set(friendIds))
            print("👥 📊 Total unique friend IDs: \(friendIds)")
            
            if friendIds.isEmpty {
                print("👥 ⚠️ No matches found in either structure")
                print("👥 📝 This could mean:")
                print("👥 📝 1. No mutual swipes have been made yet")
                print("👥 📝 2. Matches are stored in a different collection")
                print("👥 📝 3. Database structure is different than expected")
                userFriends = []
                isLoading = false
                return
            }
            
            // Get all users and filter by friend IDs
            print("👥 🔍 Fetching all users to find friend profiles...")
            let allUsers = try await authManager.fetchAllUsers()
            let friends = allUsers.filter { friendIds.contains($0.id) }
            
            print("👥 ✅ Loaded \(friends.count) friend profiles from \(friendIds.count) friend IDs")
            if friends.isEmpty && !friendIds.isEmpty {
                print("👥 ⚠️ No friend profiles found - friend IDs might not match user IDs")
                print("👥 ⚠️ Friend IDs: \(friendIds)")
                print("👥 ⚠️ Sample available user IDs: \(allUsers.prefix(3).map { "\($0.id) (\($0.name))" })")
            }
            
            for friend in friends {
                print("👤 ✅ Friend loaded: \(friend.name) (@\(friend.username)) ID: \(friend.id)")
            }
            
            userFriends = friends
            print("👥 === END LOADING FRIENDS: \(friends.count) friends loaded ===")
            
        } catch {
            print("👥 ❌ === ERROR LOADING FRIENDS ===")
            print("👥 ❌ Error: \(error)")
            if let firestoreError = error as NSError? {
                print("👥 ❌ Error code: \(firestoreError.code)")
                print("👥 ❌ Error domain: \(firestoreError.domain)")
            }
            print("👥 ❌ === END ERROR ===")
            self.error = "Failed to load friends: \(error.localizedDescription)"
            userFriends = []
        }
        
        isLoading = false
    }
    
    /// Start listening to friends changes from matches system
    func startListeningToFriends(for userId: String, authManager: AuthenticationManager) {
        print("👂 Starting to listen to matches changes for user: \(userId)")
        
        // Remove existing listener
        friendsListener?.remove()
        
        friendsListener = db.collection("matches").document(userId).collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to matches: \(error)")
                    Task { @MainActor in
                        self.error = "Failed to sync friends data"
                    }
                    return
                }
                
                print("👂 Matches collection updated, reloading friends...")
                Task {
                    await self.loadFriends(for: userId, authManager: authManager)
                }
            }
    }
    
    /// Stop listening to friends changes
    func stopListeningToFriends() {
        friendsListener?.remove()
        friendsListener = nil
    }
    
    // MARK: - Friend Discovery
    
    /// Get suggested friends (users who aren't already friends)
    func getSuggestedFriends(currentUserId: String, allUsers: [UserProfile]) -> [UserProfile] {
        let friendIds = Set(userFriends.map { $0.id })
        return allUsers.filter { user in
            user.id != currentUserId && !friendIds.contains(user.id)
        }
    }
    
    /// Search friends by name or username
    func searchFriends(query: String) -> [UserProfile] {
        guard !query.isEmpty else { return userFriends }
        
        let lowercaseQuery = query.lowercased()
        return userFriends.filter { friend in
            friend.name.lowercased().contains(lowercaseQuery) ||
            friend.username.lowercased().contains(lowercaseQuery)
        }
    }
}