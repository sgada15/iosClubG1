//
//  AlertsView.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct AlertsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showMatchPopup = false
    @State private var selectedNotification: MatchNotification?
    @State private var selectedMatchedUser: UserProfile?
    
    var body: some View {
        NavigationView {
            Group {
                if notificationManager.unreadNotifications.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No New Matches")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("When you match with someone, you'll see the notification here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Notifications List
                    List {
                        ForEach(notificationManager.unreadNotifications) { notification in
                            NotificationRow(notification: notification) {
                                handleNotificationTap(notification)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Match Alerts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showMatchPopup) {
            if let notification = selectedNotification,
               let matchedUser = selectedMatchedUser {
                MatchCelebrationPopup(
                    currentUser: getCurrentUser(),
                    matchedUser: matchedUser,
                    onDismiss: {
                        showMatchPopup = false
                        selectedNotification = nil
                        selectedMatchedUser = nil
                    }
                )
            }
        }
    }
    
    private func handleNotificationTap(_ notification: MatchNotification) {
        // Load the matched user's profile
        Task {
            do {
                if let userProfile = try await authManager.loadUserProfile(uid: notification.matchedUserId) {
                    await MainActor.run {
                        selectedNotification = notification
                        selectedMatchedUser = userProfile
                        notificationManager.markNotificationAsRead(notification)
                        showMatchPopup = true
                    }
                }
            } catch {
                print("❌ Failed to load matched user profile: \(error)")
            }
        }
    }
    
    private func getCurrentUser() -> UserProfile {
        guard let user = authManager.user else {
            return UserProfile(
                id: "",
                profilePhotoURL: nil,
                name: "User",
                username: "user",
                year: "",
                major: "",
                bio: "",
                interests: [],
                clubs: [],
                personalityAnswers: []
            )
        }
        
        return UserProfile(
            id: user.uid,
            profilePhotoURL: nil,
            name: user.displayName ?? "User",
            username: user.email?.split(separator: "@").first.map(String.init) ?? "user",
            year: "",
            major: "",
            bio: "",
            interests: [],
            clubs: [],
            personalityAnswers: []
        )
    }
}

struct NotificationRow: View {
    let notification: MatchNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Picture Placeholder
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎉 It's a Match!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("You matched with \(notification.matchedUserName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatTimeAgo(notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

// Separate popup view to avoid conflicts with the one in ExploreView
struct MatchCelebrationPopup: View {
    let currentUser: UserProfile
    let matchedUser: UserProfile
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("🎉 It's a Match! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("You and \(matchedUser.name) both want to connect!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Profile Pictures
                HStack(spacing: 30) {
                    VStack {
                        AsyncImage(url: URL(string: currentUser.profilePhotoURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        
                        Text("You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.pink)
                    
                    VStack {
                        AsyncImage(url: URL(string: matchedUser.profilePhotoURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        
                        Text(matchedUser.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Send Message") {
                        // TODO: Open chat/message functionality
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Keep Exploring") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
        }
    }
}