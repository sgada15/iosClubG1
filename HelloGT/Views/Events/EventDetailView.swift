//
//  EventDetailView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import FirebaseAuth

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var attendanceManager: EventAttendanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var friendsManager = FriendsManager()
    
    @State private var attendingFriends: [UserProfile] = []
    @State private var totalAttendeeCount = 0
    @State private var isCurrentUserAttending = false
    @State private var showingFriendProfile = false
    @State private var selectedFriend: UserProfile?
    @State private var hasInitialized = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(Event.detailRangeString(start: event.startDate, end: event.endDate))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.accentColor)
                        Text("Location")
                            .font(.headline)
                    }
                    Text(event.location)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.justify.left")
                            .foregroundColor(.accentColor)
                        Text("Description")
                            .font(.headline)
                    }
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "tag")
                            .foregroundColor(.accentColor)
                        Text("Categories")
                            .font(.headline)
                    }
                    
                    if event.categories.isEmpty {
                        CategoryPill(text: "No category")
                    } else {
                        WrapHStack(spacing: 8, lineSpacing: 8) {
                            ForEach(event.categories, id: \.self) { cat in
                                CategoryPill(text: cat)
                            }
                        }
                    }
                }
                
                // Attendance Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.accentColor)
                        Text("Attendance")
                            .font(.headline)
                    }
                    
                    // Attend/Not Attending Button
                    Button {
                        handleAttendanceToggle()
                    } label: {
                        HStack {
                            Image(systemName: isCurrentUserAttending ? "checkmark.circle.fill" : "plus.circle")
                            Text(isCurrentUserAttending ? "Attending" : "Attend Event")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCurrentUserAttending ? Color.accentColor.opacity(0.7) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(attendanceManager.isLoading)
                    
                    // Friends Attending
                    if !attendingFriends.isEmpty || totalAttendeeCount > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AttendingFriendsView.detailedAttendanceText(
                                friendsCount: attendingFriends.count,
                                totalCount: totalAttendeeCount
                            ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            if !attendingFriends.isEmpty {
                                AttendingFriendsView.forEventDetail(
                                    friends: attendingFriends,
                                    totalCount: totalAttendeeCount, // Use total attendees for the text, but overflow will be based on friends count
                                    onFriendTapped: { friend in
                                        selectedFriend = friend
                                        showingFriendProfile = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize state immediately with cached data to prevent flickering
            initializeAttendanceState()
            
            Task {
                // Load friends first
                if let currentUserId = authManager.user?.uid {
                    await friendsManager.loadFriends(for: currentUserId, authManager: authManager)
                    friendsManager.startListeningToFriends(for: currentUserId, authManager: authManager)
                }
                // Then update attendance data (this will refresh with latest data)
                loadAttendanceData()
                hasInitialized = true
            }
        }
        .onChange(of: attendanceManager.eventAttendance[event.id]) { _ in
            loadAttendanceData()
        }
        .onChange(of: friendsManager.userFriends) { _ in
            // Reload attendance data when friends list changes
            loadAttendanceData()
        }
        .onDisappear {
            friendsManager.stopListeningToFriends()
        }
        .navigationDestination(isPresented: $showingFriendProfile) {
            if let friend = selectedFriend {
                OtherProfileDetailView(profile: friend, isCurrentUser: false)
            }
        }
    }
    
    private func initializeAttendanceState() {
        // Immediately set the correct attendance state using cached data to prevent flickering
        guard let currentUserId = authManager.user?.uid else { return }
        
        // Use cached attendance data if available
        isCurrentUserAttending = attendanceManager.isUserAttending(event: event, userId: currentUserId)
        totalAttendeeCount = attendanceManager.getAttendeeCount(for: event)
        
        print("🚀 Initialized attendance state: attending=\(isCurrentUserAttending), count=\(totalAttendeeCount)")
    }
    
    private func loadAttendanceData() {
        guard let currentUserId = authManager.user?.uid else { 
            print("❌ No current user ID found")
            return 
        }
        
        if hasInitialized {
            print("📊 Updating attendance data for event: \(event.title)")
        }
        
        // Check if current user is attending
        let wasAttending = isCurrentUserAttending
        isCurrentUserAttending = attendanceManager.isUserAttending(event: event, userId: currentUserId)
        
        if hasInitialized && wasAttending != isCurrentUserAttending {
            print("📊 User attendance changed: \(wasAttending) -> \(isCurrentUserAttending)")
        }
        
        // Get total attendee count
        let oldCount = totalAttendeeCount
        totalAttendeeCount = attendanceManager.getAttendeeCount(for: event)
        
        if hasInitialized && oldCount != totalAttendeeCount {
            print("📊 Total attendee count changed: \(oldCount) -> \(totalAttendeeCount)")
        }
        
        if hasInitialized {
            print("📊 Event attendees: \(attendanceManager.getAttendees(for: event))")
        }
        
        // Use actual friends from FriendsManager
        let userFriends = friendsManager.userFriends
        if hasInitialized {
            print("👥 User has \(userFriends.count) friends")
        }
        
        // Filter friends who are attending this event
        let previousAttendingCount = attendingFriends.count
        attendingFriends = attendanceManager.getFriendsAttending(event: event, userFriends: userFriends)
        
        if hasInitialized && previousAttendingCount != attendingFriends.count {
            print("👥 Attending friends changed: \(previousAttendingCount) -> \(attendingFriends.count)")
            for friend in attendingFriends {
                print("👤 Attending friend: \(friend.name) (@\(friend.username))")
            }
        }
    }
    
    private func handleAttendanceToggle() {
        guard let currentUserId = authManager.user?.uid else {
            print("❌ No current user found")
            return
        }
        
        // Optimistic UI update
        let wasAttending = isCurrentUserAttending
        isCurrentUserAttending.toggle()
        
        // Update total count optimistically
        if isCurrentUserAttending {
            totalAttendeeCount += 1
        } else {
            totalAttendeeCount = max(0, totalAttendeeCount - 1)
        }
        
        Task {
            do {
                await attendanceManager.toggleAttendance(for: event, userId: currentUserId)
                print("✅ Successfully toggled attendance")
            } catch {
                // Revert optimistic changes on error
                await MainActor.run {
                    isCurrentUserAttending = wasAttending
                    if wasAttending {
                        totalAttendeeCount += 1
                    } else {
                        totalAttendeeCount = max(0, totalAttendeeCount - 1)
                    }
                }
                print("❌ Failed to toggle attendance: \(error)")
            }
        }
    }
}

private struct CategoryPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.systemGray6))
            )
            .overlay(
                Capsule().stroke(Color(.separator), lineWidth: 0.5)
            )
    }
}

private struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }
    
    var body: some View {
        FlowLayout(spacing: spacing, lineSpacing: lineSpacing, content: content)
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                content()
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height + lineSpacing
                        }
                        let result = width
                        if d.width <= geometry.size.width {
                            width -= d.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        height
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EventDetailView(event: Event.sampleEvents[0])
        }
    }
}

