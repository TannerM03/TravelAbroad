//
//  CommentModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

enum VoteType: String, CaseIterable {
    case upvote, downvote
}

enum CommentSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case upvotes = "Upvotes"
    case downvotes = "Downvotes"
    
    var id: String { self.rawValue }
}

// model for review of a recommendation, these are how the recommendations are calculated and this will be displayed when the user clicks on a recommended location
struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let recId: String
    let rating: Int
    let comment: String?
    let createdAt: Date
    let imageUrl: String?
    let username: String?
    
    // Vote properties (will be populated from backend)
    var upvoteCount: Int = 0
    var downvoteCount: Int = 0
    var netVotes: Int = 0
    var userVote: VoteType? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recId = "rec_id"
        case rating
        case comment
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case username
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case netVotes = "net_votes"
        case userVote = "user_vote"
    }
    
    // Memberwise initializer for creating Comment instances in code
    init(id: String, userId: String, recId: String, rating: Int, comment: String?, createdAt: Date, imageUrl: String?, username: String?, upvoteCount: Int = 0, downvoteCount: Int = 0, netVotes: Int = 0, userVote: VoteType? = nil) {
        self.id = id
        self.userId = userId
        self.recId = recId
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.imageUrl = imageUrl
        self.username = username
        self.upvoteCount = upvoteCount
        self.downvoteCount = downvoteCount
        self.netVotes = netVotes
        self.userVote = userVote
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        recId = try container.decode(String.self, forKey: .recId)
        rating = try container.decode(Int.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        
        // Vote properties with defaults
        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount) ?? 0
        downvoteCount = try container.decodeIfPresent(Int.self, forKey: .downvoteCount) ?? 0
        netVotes = try container.decodeIfPresent(Int.self, forKey: .netVotes) ?? 0
        
        // Handle userVote string -> enum conversion
        if let voteString = try container.decodeIfPresent(String.self, forKey: .userVote) {
            userVote = VoteType(rawValue: voteString)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(recId, forKey: .recId)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encode(upvoteCount, forKey: .upvoteCount)
        try container.encode(downvoteCount, forKey: .downvoteCount)
        try container.encode(netVotes, forKey: .netVotes)
        try container.encodeIfPresent(userVote?.rawValue, forKey: .userVote)
    }
}

// Temporary struct for decoding the joined data
struct RatingTemporary: Codable {
    let id: String
    let userId: String
    let recommendationId: String
    let rating: Int
    let comment: String?
    let createdAt: Date
    let imageUrl: String?
    let profiles: TempProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recommendationId = "rec_id"
        case comment
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case profiles
        case rating
    }
}

struct TempProfile: Codable {
    let username: String
}
