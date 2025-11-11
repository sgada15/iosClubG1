//
//  UserProfile.swift
//  HelloGT
//
//  Created by Sanaa Gada on 10/30/25.
//
import Foundation

struct UserProfile: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var major: String
    var year: String
    var threads: [String]
    var interests: [String]
    var clubs: [String]
    var bio: String
    var imageName: String // temporarily local image name
}
