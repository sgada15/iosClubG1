//
//  AlertsView.swift
//  BuzzBuddy
//
//  Created by Sanaa on 11/18/25.
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
            ZStack {
                // GT-themed background
                LinearGradient.gtBackgroundGradient
                    .ignoresSafeArea()
                
                Group {
                    if notificationManager.unreadNotifications.isEmpty {
                        // Empty State with GT styling
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color.gtPastelYellow.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gtSecondary)
                            }
                            
                            VStack(spacing: 12) {
                                Text("No New Matches")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gtPrimaryText)
                                
                                Text("When you match with someone, you'll see the notification here! Keep exploring to find your perfect match.")
                                    .font(.subheadline)
                                    .foregroundColor(.gtSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(40)
                    } else {
                        // Notifications List with GT styling
                        List {
                            ForEach(notificationManager.unreadNotifications) { notification in
                                NotificationRow(notification: notification) {
                                    handleNotificationTap(notification)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                    }
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
    
    // MARK: - Private Methods
    
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
                await MainActor.run {
                    print("❌ Failed to load matched user profile: \(error)")
                }
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
                // Profile Picture Placeholder with GT styling
                ZStack {
                    Circle()
                        .fill(Color.gtCardBackground)
                        .overlay(
                            Circle()
                                .stroke(Color.gtPastelYellow.opacity(0.4), lineWidth: 1)
                        )
                        .frame(width: 55, height: 55)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gtSecondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("It's a match!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gtGold)
                    
                    Text("You matched with \(notification.matchedUserName)")
                        .font(.subheadline)
                        .foregroundColor(.gtPrimaryText)
                    
                    Text(formatTimeAgo(notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.gtSecondaryText)
                }
                
                Spacer()
                
                // Unread indicator with GT colors
                if !notification.isRead {
                    Circle()
                        .fill(Color.gtBuzzGold)
                        .frame(width: 12, height: 12)
                        .shadow(color: .gtBuzzGold.opacity(0.4), radius: 3, x: 0, y: 1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gtCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gtPastelYellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .gtGold.opacity(0.1), radius: 2, x: 0, y: 1)
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
            // GT-themed background overlay
            LinearGradient(
                colors: [Color.gtNavy.opacity(0.8), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Title with GT styling
                VStack(spacing: 12) {
                    Text("It's a match!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.gtGold)
                        .multilineTextAlignment(.center)
                    
                    Text("You and \(matchedUser.name) both want to connect!")
                        .font(.subheadline)
                        .foregroundColor(.gtPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                // Profile Pictures with GT styling
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        AsyncImage(url: URL(string: currentUser.profilePhotoURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(.gtSecondary)
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.gtGoldGradient, lineWidth: 3)
                        )
                        .shadow(color: .gtGold.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("You")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gtSecondaryText)
                    }
                    
                    // Heart with GT colors
                    ZStack {
                        Circle()
                            .fill(Color.gtBuzzGold.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gtBuzzGold)
                    }
                    .scaleEffect(1.2)
                    .shadow(color: .gtBuzzGold.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    VStack(spacing: 8) {
                        AsyncImage(url: URL(string: matchedUser.profilePhotoURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(.gtSecondary)
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.gtGoldGradient, lineWidth: 3)
                        )
                        .shadow(color: .gtGold.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text(matchedUser.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gtSecondaryText)
                            .lineLimit(1)
                    }
                }
                
                // Action Buttons with GT styling
                VStack(spacing: 16) {
                    Button("Send Message") {
                        // TODO: Open chat/message functionality
                        onDismiss()
                    }
                    .buttonStyle(.gtPrimary)
                    .frame(maxWidth: .infinity)
                    
                    Button("Keep Exploring") {
                        onDismiss()
                    }
                    .buttonStyle(.gtSecondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient.gtCardGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gtPastelYellow.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .gtGold.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }
}
