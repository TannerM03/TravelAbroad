//
//  NotificationAlertViewModel.swift
//  Vista
//
//  Created by Tanner Macpherson on 12/22/25.
//

import Foundation
import Observation

@MainActor
@Observable
class NotificationAlertViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false
    var errorMessage: String?
    var unreadCount: Int = 0
    
    private let supabaseManager = SupabaseManager.shared
    
    func fetchNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            notifications = try await supabaseManager.fetchNotifications()
            await fetchUnreadCount()
        } catch {
            errorMessage = "Failed to load notifs: \(error.localizedDescription)"
            print("error fetching notifications: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func fetchUnreadCount() async {
        do {
            unreadCount = try await supabaseManager.fetchUnreadNotificationCount()
        } catch {
            errorMessage = "Failed to load notif count: \(error.localizedDescription)"
            print("error fetching notif count")
        }
    }
    
    func markAsRead(notification: AppNotification) async {
        do {
            try await supabaseManager.markNotificationAsRead(notificationId: notification.id)
            
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                let updatedNotification = notification
                notifications[index] = updatedNotification
            }
            
            await fetchUnreadCount()
        } catch {
            print("error marking single notififcation as read")
        }
    }
    
    func markAllAsRead() async {
        do {
            try await supabaseManager.markAllNotificationsAsRead()
            await fetchNotifications()
            unreadCount = 0
        } catch {
            print("error marking all notifs as read")
        }
    }
    
    func refresh() async {
        await fetchNotifications()
    }
}
