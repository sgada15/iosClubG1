//
//  SwipeDecision.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation

struct SwipeDecision: Codable {
    let userId: String
    let targetUserId: String
    let decision: SwipeType
    let timestamp: Date
}

enum SwipeType: String, Codable {
    case like = "right"
    case pass = "left"
}

struct Match: Codable, Identifiable, Equatable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
    
    init(user1Id: String, user2Id: String) {
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.createdAt = Date()
        // Create consistent match ID regardless of order
        let sortedIds = [user1Id, user2Id].sorted()
        self.id = "\(sortedIds[0])_\(sortedIds[1])"
    }
}

struct UserSwipeData: Codable {
    var rightSwipes: [String] = []
    var leftSwipes: [String] = []
    var matches: [String] = []
}