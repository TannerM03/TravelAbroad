//
//  Notification.swift
//  Vista
//
//  Created by Tanner Macpherson on 12/13/25.
//

import Foundation

enum AppNotificationType: String, Codable {
    case newFollower = "new_follower"
    // newc omment
    // new like
}

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let actorUserId: UUID
    let type: AppNotificationType
    let createdAt: Date
    let readAt: Date?
    
    let actorUsername: String?
    let actorImageUrl: String?
    let actorIsPopular: Bool
    
    enum CodingKeys: String, CodingKey  {
        case id
        case userId = "user_id"
        case actorUserId = "actor_id"
        case type
        case createdAt = "created_at"
        case readAt = "read_at"
        case actorUsername = "actor_username"
        case actorImageUrl = "actor_image_url"
        case actorIsPopular = "is_popular"
    }
    
    var isRead: Bool {
        readAt != nil
    }
    
    var timeAgo: String {
        createdAt.timeAgoOrDateString()
    }
}


