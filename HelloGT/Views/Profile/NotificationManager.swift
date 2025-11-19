//
//  NotificationManager.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import Foundation
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    @Published var matchNotifications: [MatchNotification] = []
    @Published var unreadCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private var notificationsKey: String = ""
    
    init() {}
    
    func setCurrentUser(userId: String) {
        notificationsKey = "matchNotifications_\(userId)"
        loadNotifications()
    }
    
    // MARK: - Add New Match Notification
    
    func addMatchNotification(match: Match, currentUserId: String, matchedUserName: String) {
        let notification = MatchNotification(
            match: match,
            currentUserId: currentUserId,
            matchedUserName: matchedUserName
        )
        
        // Check if notification already exists
        if !matchNotifications.contains(where: { $0.matchId == match.id }) {
            matchNotifications.append(notification)
            updateUnreadCount()
            saveNotifications()
            
            print("🔔 Added match notification for \(matchedUserName)")
        }
    }
    
    // MARK: - Mark Notification as Read
    
    func markNotificationAsRead(_ notification: MatchNotification) {
        if let index = matchNotifications.firstIndex(where: { $0.id == notification.id }) {
            matchNotifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
            
            print("👁️ Marked notification as read: \(notification.matchedUserName)")
        }
    }
    
    // MARK: - Get Unread Notifications
    
    var unreadNotifications: [MatchNotification] {
        return matchNotifications.filter { !$0.isRead }
    }
    
    // MARK: - Get Acknowledged Match IDs
    
    /// Returns match IDs that have been acknowledged (notification has been read/opened)
    /// Matches should only appear in Friends tab after being acknowledged
    var acknowledgedMatchIds: Set<String> {
        return Set(matchNotifications.filter { $0.isRead }.map { $0.matchId })
    }
    
    /// Check if a match has been acknowledged (notification opened)
    func isMatchAcknowledged(matchId: String) -> Bool {
        return acknowledgedMatchIds.contains(matchId)
    }
    
    // MARK: - Update Unread Count
    
    private func updateUnreadCount() {
        unreadCount = unreadNotifications.count
    }
    
    // MARK: - Persistence
    
    private func saveNotifications() {
        guard !notificationsKey.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(matchNotifications)
            userDefaults.set(data, forKey: notificationsKey)
            print("💾 Saved \(matchNotifications.count) notifications")
        } catch {
            print("❌ Failed to save notifications: \(error)")
        }
    }
    
    private func loadNotifications() {
        guard !notificationsKey.isEmpty else { return }
        
        guard let data = userDefaults.data(forKey: notificationsKey) else {
            print("📭 No saved notifications found")
            return
        }
        
        do {
            matchNotifications = try JSONDecoder().decode([MatchNotification].self, from: data)
            updateUnreadCount()
            print("✅ Loaded \(matchNotifications.count) notifications (\(unreadCount) unread)")
        } catch {
            print("❌ Failed to load notifications: \(error)")
            matchNotifications = []
            unreadCount = 0
        }
    }
    
    // MARK: - Clear All Notifications (Optional)
    
    func clearAllNotifications() {
        matchNotifications.removeAll()
        unreadCount = 0
        saveNotifications()
        print("🗑️ Cleared all notifications")
    }
}