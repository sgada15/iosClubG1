//
//  UserProfile.swift
//  HelloGT
//
//  Created by Sanaa Gada on 10/30/25.
//
import Foundation

struct UserProfile: Identifiable, Codable {
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
}
