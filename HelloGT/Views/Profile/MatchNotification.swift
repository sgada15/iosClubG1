//
//  MatchNotification.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation

struct MatchNotification: Identifiable, Codable, Equatable {
    let id: String
    let matchId: String
    let currentUserId: String
    let matchedUserId: String
    let matchedUserName: String
    let createdAt: Date
    var isRead: Bool = false
    
    init(match: Match, currentUserId: String, matchedUserName: String) {
        self.id = UUID().uuidString
        self.matchId = match.id
        self.currentUserId = currentUserId
        // Determine which user is the "other" user
        self.matchedUserId = match.user1Id == currentUserId ? match.user2Id : match.user1Id
        self.matchedUserName = matchedUserName
        self.createdAt = match.createdAt
        self.isRead = false
    }
}