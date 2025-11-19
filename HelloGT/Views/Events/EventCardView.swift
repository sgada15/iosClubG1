//
//  EventCardView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import FirebaseAuth

struct EventCardView: View {
    let event: Event
    @EnvironmentObject var attendanceManager: EventAttendanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var friendsManager = FriendsManager()
    
    @State private var attendingFriends: [UserProfile] = []
    @State private var totalAttendeeCount = 0
    
    private var salsaIconName: String? {
        guard let name = event.iconSystemName else { return nil }
        if UIImage(systemName: name) != nil {
            return name
        } else {
            return "music.note.list"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = salsaIconName {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 34, height: 34, alignment: .topLeading)
                    .padding(.top, 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(Event.listDateString(for: event.startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Attending friends section
                if !attendingFriends.isEmpty || totalAttendeeCount > 0 {
                    HStack(alignment: .center, spacing: 8) {
                        AttendingFriendsView.forEventCard(
                            friends: attendingFriends,
                            totalCount: totalAttendeeCount
                        )
                        
                        if !attendingFriends.isEmpty {
                            Text(AttendingFriendsView.attendanceText(
                                friendsCount: attendingFriends.count,
                                totalCount: totalAttendeeCount
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .padding(.horizontal)
        .onAppear {
            Task {
                // Load friends first if not already loaded
                if let currentUserId = authManager.user?.uid, friendsManager.userFriends.isEmpty {
                    await friendsManager.loadFriends(for: currentUserId, authManager: authManager)
                }
                // Then load attending friends
                loadAttendingFriends()
            }
        }
        .onChange(of: attendanceManager.eventAttendance[event.id]) { _ in
            loadAttendingFriends()
        }
        .onChange(of: friendsManager.userFriends) { _ in
            // Reload when friends list changes
            loadAttendingFriends()
        }
    }
    
    private func loadAttendingFriends() {
        // Get total attendee count
        totalAttendeeCount = attendanceManager.getAttendeeCount(for: event)
        
        // Use actual friends from FriendsManager
        let userFriends = friendsManager.userFriends
        
        // Filter friends who are attending
        attendingFriends = attendanceManager.getFriendsAttending(event: event, userFriends: userFriends)
        
        print("🎫 Event: \(event.title) - \(attendingFriends.count) friends attending, \(totalAttendeeCount) total")
    }
}

struct EventCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EventCardView(event: Event.sampleEvents[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.light)
            EventCardView(event: Event.sampleEvents[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}

