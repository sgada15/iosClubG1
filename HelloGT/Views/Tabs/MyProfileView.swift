//
//  MyProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct MyProfileView: View {
    // Sample profile data for current user - you'll replace this later
    @State private var currentUserProfile: UserProfile = UserProfile(
        id: "current-user",
        name: "Alex Johnson",
        major: "Computer Science",
        year: "Senior",
        threads: [""],
        interests: ["Coding", "Hiking", "Photography", "Music"],
        clubs: ["CS Club", "Outdoor Adventures", "Photography Society"],
        bio: "Computer Science student passionate about software development and outdoor adventures. Love building apps and capturing moments through photography.",
        imageName: "AppIcon"
    )
    
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            OtherProfileDetailView(
                profile: currentUserProfile,
                isCurrentUser: true,
                onEdit: {
                    showEditProfile = true
                }
            )
            .sheet(isPresented: $showEditProfile) {
                NavigationView {
                    EditProfileView()
                        .navigationTitle("Edit Profile")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
