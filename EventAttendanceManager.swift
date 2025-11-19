//
//  EventAttendanceManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class EventAttendanceManager: ObservableObject {
    @Published var eventAttendance: [String: [String]] = [:] // eventId -> [userIds]
    @Published var userEventAttendance: [String: Set<String>] = [:] // userId -> Set of eventIds
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    deinit {
        // Clean up listeners
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - Attendance Management
    
    /// Toggle attendance for current user at an event
    func toggleAttendance(for event: Event, userId: String) async {
        print("🔄 Toggling attendance for user \(userId) at event \(event.id): \(event.title)")
        let isCurrentlyAttending = isUserAttending(event: event, userId: userId)
        print("🔄 Currently attending: \(isCurrentlyAttending)")
        
        if isCurrentlyAttending {
            print("🔄 Removing attendance...")
            await removeAttendance(for: event, userId: userId)
        } else {
            print("🔄 Adding attendance...")
            await addAttendance(for: event, userId: userId)
        }
    }
    
    /// Add user attendance to an event
    func addAttendance(for event: Event, userId: String) async {
        print("➕ === ADDING ATTENDANCE ===")
        print("➕ Event ID: '\(event.id)'")
        print("➕ Event Title: '\(event.title)'")
        print("➕ User ID: '\(userId)'")
        
        do {
            let attendanceRef = db.collection("eventAttendance").document(event.id)
            let documentPath = "eventAttendance/\(event.id)"
            print("➕ Firebase document path: \(documentPath)")
            
            // Check if document exists first
            let existingDoc = try await attendanceRef.getDocument()
            print("➕ Document exists: \(existingDoc.exists)")
            if existingDoc.exists {
                let data = existingDoc.data()
                print("➕ Existing data: \(data ?? [:])")
            }
            
            let dataToWrite: [String: Any] = [
                "attendeeIds": FieldValue.arrayUnion([userId]),
                "eventId": event.id,
                "eventTitle": event.title,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            print("➕ Data being written: \(dataToWrite)")
            
            // Use arrayUnion to add userId if not already present
            try await attendanceRef.setData(dataToWrite, merge: true)
            
            print("➕ ✅ Firebase write completed successfully")
            
            // Verify the write
            let verificationDoc = try await attendanceRef.getDocument()
            if let verificationData = verificationDoc.data() {
                print("➕ 🔍 Verification - document after write: \(verificationData)")
                if let attendeeIds = verificationData["attendeeIds"] as? [String] {
                    print("➕ 🔍 Attendee IDs in Firebase: \(attendeeIds)")
                    print("➕ 🔍 User \(userId) is in list: \(attendeeIds.contains(userId))")
                }
            }
            
            // Update local state optimistically
            var attendees = eventAttendance[event.id] ?? []
            let wasInList = attendees.contains(userId)
            if !wasInList {
                attendees.append(userId)
                eventAttendance[event.id] = attendees
                print("➕ ✅ Updated local state: \(attendees) (\(attendees.count) total)")
            } else {
                print("➕ ℹ️ User already in local list: \(attendees)")
            }
            
            // Update user's attendance set
            var userEvents = userEventAttendance[userId] ?? Set<String>()
            userEvents.insert(event.id)
            userEventAttendance[userId] = userEvents
            print("➕ ✅ Updated user attendance set: \(userEvents)")
            
            print("➕ ✅ SUCCESS: Added attendance for user \(userId) to event \(event.title)")
            print("➕ === END ADDING ATTENDANCE ===")
            
        } catch {
            print("➕ ❌ === FIREBASE ERROR ===")
            print("➕ ❌ Error type: \(type(of: error))")
            print("➕ ❌ Error description: \(error.localizedDescription)")
            print("➕ ❌ Full error: \(error)")
            if let firestoreError = error as NSError? {
                print("➕ ❌ Error code: \(firestoreError.code)")
                print("➕ ❌ Error domain: \(firestoreError.domain)")
                print("➕ ❌ User info: \(firestoreError.userInfo)")
            }
            print("➕ ❌ === END ERROR ===")
            self.error = "Failed to join event: \(error.localizedDescription)"
        }
    }
    
    /// Remove user attendance from an event
    func removeAttendance(for event: Event, userId: String) async {
        print("➖ Removing attendance for user \(userId) from event \(event.id)")
        do {
            let attendanceRef = db.collection("eventAttendance").document(event.id)
            
            // Use arrayRemove to remove userId
            try await attendanceRef.updateData([
                "attendeeIds": FieldValue.arrayRemove([userId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            print("➖ Firebase remove successful")
            
            // Update local state optimistically
            var attendees = eventAttendance[event.id] ?? []
            attendees.removeAll { $0 == userId }
            eventAttendance[event.id] = attendees
            print("➖ Updated local state: \(attendees)")
            
            // Update user's attendance set
            var userEvents = userEventAttendance[userId] ?? Set<String>()
            userEvents.remove(event.id)
            userEventAttendance[userId] = userEvents
            
            print("✅ Removed attendance for user \(userId) from event \(event.title)")
            
        } catch {
            print("❌ Failed to remove attendance: \(error)")
            self.error = "Failed to leave event: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Query Methods
    
    /// Check if a user is attending an event
    func isUserAttending(event: Event, userId: String) -> Bool {
        let attendees = eventAttendance[event.id] ?? []
        let isAttending = attendees.contains(userId)
        print("🔍 === CHECKING ATTENDANCE ===")
        print("🔍 Event ID: '\(event.id)'")
        print("🔍 Event Title: '\(event.title)'") 
        print("🔍 User ID: '\(userId)'")
        print("🔍 All event attendance keys: \(Array(eventAttendance.keys))")
        print("🔍 Attendees for this event: \(attendees)")
        print("🔍 Is user attending: \(isAttending)")
        print("🔍 === END CHECKING ATTENDANCE ===")
        return isAttending
    }
    
    /// Get all attendees for an event
    func getAttendees(for event: Event) -> [String] {
        return eventAttendance[event.id] ?? []
    }
    
    /// Get attendee count for an event
    func getAttendeeCount(for event: Event) -> Int {
        return eventAttendance[event.id]?.count ?? 0
    }
    
    /// Get events that a user is attending
    func getEventsUserIsAttending(userId: String) -> Set<String> {
        return userEventAttendance[userId] ?? Set<String>()
    }
    
    // MARK: - Friends Integration
    
    /// Get friends who are attending a specific event
    func getFriendsAttending(event: Event, userFriends: [UserProfile]) -> [UserProfile] {
        let attendeeIds = getAttendees(for: event)
        let friendIds = Set(userFriends.map { $0.id })
        
        // Find intersection of attendees and friends
        let attendingFriendIds = Set(attendeeIds).intersection(friendIds)
        
        return userFriends.filter { attendingFriendIds.contains($0.id) }
    }
    
    // MARK: - Real-time Updates
    
    /// Start listening to attendance changes for all events
    func startListeningToAttendance() {
        print("📡 === STARTING ATTENDANCE LISTENER ===")
        // Clear existing listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        let listener = db.collection("eventAttendance")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("📡 ❌ Error listening to attendance: \(error)")
                    Task { @MainActor in
                        self.error = "Failed to load attendance data"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("📡 ⚠️ No documents in snapshot")
                    return 
                }
                
                print("📡 📊 Received \(documents.count) documents from Firebase")
                
                Task { @MainActor in
                    var newEventAttendance: [String: [String]] = [:]
                    var newUserEventAttendance: [String: Set<String>] = [:]
                    
                    for document in documents {
                        let data = document.data()
                        let eventId = document.documentID
                        let attendeeIds = data["attendeeIds"] as? [String] ?? []
                        
                        print("📡 📄 Event: \(eventId)")
                        print("📡 📄 Attendees: \(attendeeIds)")
                        print("📡 📄 Full data: \(data)")
                        
                        newEventAttendance[eventId] = attendeeIds
                        
                        // Update user -> events mapping
                        for userId in attendeeIds {
                            var userEvents = newUserEventAttendance[userId] ?? Set<String>()
                            userEvents.insert(eventId)
                            newUserEventAttendance[userId] = userEvents
                        }
                    }
                    
                    let oldCount = self.eventAttendance.count
                    self.eventAttendance = newEventAttendance
                    self.userEventAttendance = newUserEventAttendance
                    
                    print("📡 ✅ Updated attendance data: \(oldCount) -> \(newEventAttendance.count) events")
                    print("📡 ✅ Event attendance summary:")
                    for (eventId, attendees) in newEventAttendance {
                        print("📡     \(eventId): \(attendees.count) attendees \(attendees)")
                    }
                    print("📡 === END ATTENDANCE LISTENER UPDATE ===")
                }
            }
        
        listeners.append(listener)
        print("📡 ✅ Attendance listener started")
    }
    
    /// Stop listening to attendance changes
    func stopListeningToAttendance() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Batch Operations
    
    /// Load attendance data for specific events
    func loadAttendanceForEvents(_ eventIds: [String]) async {
        guard !eventIds.isEmpty else { return }
        
        isLoading = true
        
        do {
            let snapshot = try await db.collection("eventAttendance")
                .whereField(FieldPath.documentID(), in: eventIds)
                .getDocuments()
            
            var newEventAttendance: [String: [String]] = [:]
            
            for document in snapshot.documents {
                let data = document.data()
                let eventId = document.documentID
                let attendeeIds = data["attendeeIds"] as? [String] ?? []
                newEventAttendance[eventId] = attendeeIds
            }
            
            // Merge with existing data
            for (eventId, attendees) in newEventAttendance {
                eventAttendance[eventId] = attendees
            }
            
            print("📡 Loaded attendance for \(newEventAttendance.count) events")
            
        } catch {
            print("❌ Failed to load attendance: \(error)")
            self.error = "Failed to load attendance data"
        }
        
        isLoading = false
    }
}