//
//  UserProfile.swift
//  HelloGT
//
//  Created by Sanaa Gada on 10/30/25.
//
import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String
    var profilePhotoURL: String?
    var name: String
    var username: String
    var year: String // 2025, 2026, 2027, 2028, 2029, 2030
    var major: String
    var bio: String
    var interests: [String]
    var clubs: [String]
    var personalityAnswers: [String] // size 4
    
    // MARK: - Profile Completion Logic
    var isComplete: Bool {
        return !name.isEmpty &&
               !username.isEmpty &&
               !major.isEmpty &&
               !year.isEmpty &&
               bio.count >= 20 &&
               interests.count >= 2 &&
               clubs.count >= 1 &&
               personalityAnswers.count == 4 &&
               personalityAnswers.allSatisfy { !$0.isEmpty }
    }
    
    var completionPercentage: Double {
        var completed = 0
        let total = 8
        
        if !name.isEmpty { completed += 1 }
        if !username.isEmpty { completed += 1 }
        if !major.isEmpty { completed += 1 }
        if !year.isEmpty { completed += 1 }
        if bio.count >= 20 { completed += 1 }
        if interests.count >= 2 { completed += 1 }
        if clubs.count >= 1 { completed += 1 }
        if personalityAnswers.count == 4 && personalityAnswers.allSatisfy({ !$0.isEmpty }) { completed += 1 }
        
        return Double(completed) / Double(total)
    }
}
