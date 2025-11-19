//
//  AttendingFriendsView.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import SwiftUI

struct AttendingFriendsView: View {
    let friends: [UserProfile]
    let totalCount: Int
    let profileSize: CGFloat
    let maxVisible: Int
    let onFriendTapped: ((UserProfile) -> Void)?
    
    init(
        friends: [UserProfile],
        totalCount: Int? = nil,
        profileSize: CGFloat = 24,
        maxVisible: Int = 3,
        onFriendTapped: ((UserProfile) -> Void)? = nil
    ) {
        self.friends = friends
        self.totalCount = totalCount ?? friends.count
        self.profileSize = profileSize
        self.maxVisible = maxVisible
        self.onFriendTapped = onFriendTapped
    }
    
    private var visibleFriends: [UserProfile] {
        Array(friends.prefix(maxVisible))
    }
    
    private var overflowCount: Int {
        max(0, friends.count - maxVisible)
    }
    
    private var overlappingOffset: CGFloat {
        profileSize * 0.7 // Each profile overlaps 70% of the previous one
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if friends.isEmpty {
                // No friends attending
                EmptyView()
            } else {
                // Overlapping profile pictures
                ZStack(alignment: .leading) {
                    ForEach(Array(visibleFriends.enumerated()), id: \.element.id) { index, friend in
                        ProfilePictureView(
                            friend: friend,
                            size: profileSize,
                            onTapped: onFriendTapped
                        )
                        .offset(x: CGFloat(index) * overlappingOffset)
                        .zIndex(Double(maxVisible - index)) // Reverse z-index so first friend is on top
                    }
                }
                .frame(width: profileSize + CGFloat(max(0, visibleFriends.count - 1)) * overlappingOffset, alignment: .leading)
                
                // Overflow counter
                if overflowCount > 0 {
                    OverflowCounterView(
                        count: overflowCount,
                        size: profileSize
                    )
                    .offset(x: overlappingOffset)
                }
            }
            
            Spacer() // Push everything to the left
        }
    }
}

private struct ProfilePictureView: View {
    let friend: UserProfile
    let size: CGFloat
    let onTapped: ((UserProfile) -> Void)?
    
    var body: some View {
        Button {
            onTapped?(friend)
        } label: {
            AsyncImage(url: URL(string: friend.profilePhotoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.gray)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(ProfileButtonStyle())
    }
}

private struct OverflowCounterView: View {
    let count: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
            
            Text("+\(count)")
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

private struct ProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

extension AttendingFriendsView {
    /// For event card view (small size)
    static func forEventCard(
        friends: [UserProfile],
        totalCount: Int? = nil,
        onFriendTapped: ((UserProfile) -> Void)? = nil
    ) -> AttendingFriendsView {
        AttendingFriendsView(
            friends: friends,
            totalCount: totalCount,
            profileSize: 24,
            maxVisible: 3,
            onFriendTapped: onFriendTapped
        )
    }
    
    /// For event detail view (larger size)
    static func forEventDetail(
        friends: [UserProfile],
        totalCount: Int? = nil,
        onFriendTapped: ((UserProfile) -> Void)? = nil
    ) -> AttendingFriendsView {
        AttendingFriendsView(
            friends: friends,
            totalCount: totalCount,
            profileSize: 36,
            maxVisible: 3,
            onFriendTapped: onFriendTapped
        )
    }
}

// MARK: - Text Extensions

extension AttendingFriendsView {
    /// Creates text describing friends attendance
    static func attendanceText(friendsCount: Int, totalCount: Int) -> String {
        if friendsCount == 0 {
            return "\(totalCount) attending"
        } else if friendsCount == 1 {
            return "1 friend attending"
        } else {
            return "\(friendsCount) friends attending"
        }
    }
    
    /// Creates detailed text for event detail view
    static func detailedAttendanceText(friendsCount: Int, totalCount: Int) -> String {
        let friendsText = friendsCount == 1 ? "friend is" : "friends are"
        let totalText = totalCount == 1 ? "person" : "people"
        
        if friendsCount == 0 {
            return "\(totalCount) \(totalText) attending"
        } else {
            return "\(friendsCount) \(friendsText) attending • \(totalCount) total"
        }
    }
}

// MARK: - Preview

struct AttendingFriendsView_Previews: PreviewProvider {
    static let sampleFriends = [
        UserProfile(id: "1", profilePhotoURL: nil, name: "Alice", username: "alice", year: "2025", major: "CS", bio: "", interests: [], clubs: [], personalityAnswers: []),
        UserProfile(id: "2", profilePhotoURL: nil, name: "Bob", username: "bob", year: "2025", major: "EE", bio: "", interests: [], clubs: [], personalityAnswers: []),
        UserProfile(id: "3", profilePhotoURL: nil, name: "Charlie", username: "charlie", year: "2025", major: "ME", bio: "", interests: [], clubs: [], personalityAnswers: []),
        UserProfile(id: "4", profilePhotoURL: nil, name: "Diana", username: "diana", year: "2025", major: "IE", bio: "", interests: [], clubs: [], personalityAnswers: [])
    ]
    
    static var previews: some View {
        VStack(spacing: 20) {
            // Small version (for event cards)
            AttendingFriendsView.forEventCard(friends: Array(sampleFriends.prefix(2)))
            
            // With overflow
            AttendingFriendsView.forEventCard(friends: sampleFriends, totalCount: 8)
            
            // Large version (for event details)
            AttendingFriendsView.forEventDetail(friends: Array(sampleFriends.prefix(3)))
            
            // Large with overflow
            AttendingFriendsView.forEventDetail(friends: sampleFriends, totalCount: 12)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}