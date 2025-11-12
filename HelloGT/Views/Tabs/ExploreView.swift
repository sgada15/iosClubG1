//
//  ExploreView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct ExploreView: View {
    @State private var currentProfileIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isShowingDetailView = false
    
    // Sample profiles for the explore feed
    @State private var exploreProfiles: [UserProfile] = [
        UserProfile(
            name: "Sarah Kim",
            major: "Mechanical Engineering", 
            year: "Junior",
            threads: ["@sarahkim.gt"],
            interests: ["Robotics", "3D Printing", "Rock Climbing", "Cooking"],
            clubs: ["Robotics Club", "Women in Engineering", "Climbing Club"],
            bio: "Mechanical Engineering student passionate about robotics and automation. Love building things and solving complex problems. Always up for an adventure!",
            imageName: "person4"
        ),
        UserProfile(
            name: "Marcus Thompson",
            major: "Business Administration",
            year: "Sophomore", 
            threads: ["@marcusthompson.gt"],
            interests: ["Entrepreneurship", "Basketball", "Finance", "Music Production"],
            clubs: ["Entrepreneurship Club", "Investment Club", "Basketball Intramurals"],
            bio: "Business student with a passion for startups and innovation. Love connecting with like-minded people and exploring new opportunities.",
            imageName: "person5"
        ),
        UserProfile(
            name: "Emma Rodriguez",
            major: "Industrial Design",
            year: "Senior",
            threads: ["@emmarodriguez.gt"],
            interests: ["Design", "Sustainability", "Photography", "Yoga"],
            clubs: ["Design Society", "Sustainability Club", "Photo Club"],
            bio: "Industrial Design student focused on sustainable design solutions. Passionate about creating products that make a positive impact on the world.",
            imageName: "person6"
        ),
        UserProfile(
            name: "David Park",
            major: "Computer Science",
            year: "Graduate Student",
            threads: ["@davidpark.gt"],
            interests: ["AI/ML", "Gaming", "Coffee", "Hiking"],
            clubs: ["AI Research Group", "Gaming Society", "Graduate Student Association"],
            bio: "CS grad student researching machine learning applications. Love discussing tech trends over good coffee and exploring Georgia's hiking trails.",
            imageName: "person7"
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack {
                    if currentProfileIndex < exploreProfiles.count {
                        ProfileCard(
                            profile: exploreProfiles[currentProfileIndex],
                            dragOffset: dragOffset,
                            onTap: { isShowingDetailView = true },
                            onSave: { saveProfile(exploreProfiles[currentProfileIndex]) }
                        )
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 10)))
                        .scaleEffect(1.0 - abs(dragOffset.width) / 1000)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    let dragDistance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
                                    
                                    if dragDistance < 10 {
                                        // This was a tap, not a drag
                                        isShowingDetailView = true
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            dragOffset = .zero
                                        }
                                    } else if abs(gesture.translation.width) > 100 {
                                        // Swipe threshold reached
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            dragOffset = CGSize(
                                                width: gesture.translation.width > 0 ? 1000 : -1000,
                                                height: gesture.translation.height
                                            )
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            moveToNextProfile()
                                        }
                                    } else {
                                        // Return to center
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                        .animation(.easeOut, value: dragOffset)
                        
                        Spacer()
                        
                        Text("Swipe left or right to see more profiles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Text("Tap to view full profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                    } else {
                        // No more profiles
                        VStack(spacing: 16) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No more profiles")
                                .font(.title2)
                                .bold()
                            
                            Text("Check back later for more Georgia Tech students!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Reset") {
                                resetProfiles()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingDetailView) {
                if currentProfileIndex < exploreProfiles.count {
                    OtherProfileDetailView(profile: exploreProfiles[currentProfileIndex])
                }
            }
        }
    }
    
    private func moveToNextProfile() {
        currentProfileIndex += 1
        dragOffset = .zero
    }
    
    private func resetProfiles() {
        withAnimation {
            currentProfileIndex = 0
            dragOffset = .zero
        }
    }
    
    private func saveProfile(_ profile: UserProfile) {
        // TODO: Implement save functionality
        print("Saving profile: \(profile.name)")
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    let dragOffset: CGSize
    let onTap: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        // Commented out Button wrapper to prevent tap conflicts with drag gesture
        // Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Profile picture and save button
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(profile.imageName.isEmpty ? "AppIcon" : profile.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 8)
                        
                        VStack(spacing: 4) {
                            Text(profile.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text("\(profile.major) • \(profile.year)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button(action: onSave) {
                            Image(systemName: "bookmark")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .padding(12)
                                .background(Circle().fill(Color(.systemGray6)))
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                
                // About section
                if !profile.bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(profile.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                    }
                }
                
                // Quick interests preview
                if !profile.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(profile.interests.prefix(3).joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        if profile.interests.count > 3 {
                            Text("and \(profile.interests.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Commented out tap indicator since tapping is disabled
                /*
                HStack {
                    Spacer()
                    Text("Tap to view full profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                */
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        // }  // Commented out Button closing brace
        // .buttonStyle(.plain)  // Commented out button style
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}
