//
//  SupabaseManager.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/1/25.
//

import Foundation
import Supabase
import UIKit

class SupabaseManager {
    static let shared = SupabaseManager()

    let supabase: SupabaseClient = {
        let url = ConfigManager.shared.supabaseURL
        let key = ConfigManager.shared.supabaseKey

        guard let supabaseURL = URL(string: url) else {
            fatalError("Invalid Supabase URL: \(url)")
        }

        return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
    }()

    // MARK: - CitiesView Functions

    // fetches the cities to be displayed as travel options,
    func fetchCities() async throws -> [City] {
        guard let userId = supabase.auth.currentUser?.id else {
            let cities: [City] = try await supabase.from("city_with_avg_rating")
                .select()
                .execute()
                .value
            return cities
        }
        struct CityWithUserRating: Codable {
            let id: String
            let name: String
            let country: String
            let imageUrl: String?
            let avgRating: Double?
            let latitude: Double
            let longitude: Double
            let cityReviews: [UserReview]?
            let userBucketList: [BucketListEntry]?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case country
                case imageUrl = "image_url"
                case avgRating = "avg_rating"
                case latitude
                case longitude
                case cityReviews = "city_reviews"
                case userBucketList = "user_bucket_list"
            }
        }

        struct BucketListEntry: Codable {
            let cityId: String

            enum CodingKeys: String, CodingKey {
                case cityId = "city_id"
            }
        }

        struct UserReview: Codable {
            let overallRating: Double

            enum CodingKeys: String, CodingKey {
                case overallRating = "overall_rating"
            }
        }

        let response: [CityWithUserRating] = try await supabase
            .from("city_with_avg_rating")
            .select("*, city_reviews!left(overall_rating), user_bucket_list!left(city_id)")
            .eq("city_reviews.user_id", value: userId.uuidString)
            .eq("user_bucket_list.user_id", value: userId.uuidString)
            .execute()
            .value

        return response.map { cityData in
            let isBucketList = cityData.userBucketList?.first?.cityId != nil
            return City(id: cityData.id, name: cityData.name, country: cityData.country, imageUrl: cityData.imageUrl, avgRating: cityData.avgRating, latitude: cityData.latitude, longitude: cityData.longitude, userRating: cityData.cityReviews?.first?.overallRating, isBucketList: isBucketList)
        }
    }

    func fetchCityCoordinates(cityId: UUID) async throws -> (Double, Double) {
        struct CityCoordinates: Codable {
            let latitude: Double
            let longitude: Double
        }

        let response: [CityCoordinates] = try await supabase
            .from("cities")
            .select("latitude, longitude")
            .eq("id", value: cityId)
            .execute()
            .value

        guard let cityData = response.first else {
            print("❌ SupabaseManager: City not found for ID: \(cityId)")
            throw NSError(domain: "SupabaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "City not found"])
        }

        let latitude = cityData.latitude
        let longitude = cityData.longitude

        return (latitude, longitude)
    }

    // MARK: - RecommendationsView Functions

    // fetches the recommended place (restaurants, hostels, bars, etc.) for whichever city is specified in with the cityId parameter. Also has avg rating
    func fetchRecommendations(cityId: UUID) async throws -> [Recommendation] {
        let recs: [Recommendation] = try await supabase
            .from("rec_with_avg_rating")
            .select()
            .eq("city_id", value: cityId)
            .order("avg_rating", ascending: false)
            .execute()
            .value

        return recs
    }

    func saveSummaryToDatabase(recommendationId: String, summary: String) async throws {
        try await supabase
            .from("recommendations")
            .update([
                "ai_summary": summary,
                "summary_updated_at": ISO8601DateFormatter().string(from: Date()),
            ])
            .eq("id", value: recommendationId)
            .execute()
    }

    func fetchSingleRecommendation(recommendationId: String) async throws -> Recommendation {
        let rec: Recommendation = try await supabase
            .from("rec_with_avg_rating")
            .select()
            .eq("id", value: recommendationId)
            .single()
            .execute()
            .value

        return rec
    }

    func createRecommendation(
        cityId: String,
        name: String,
        description: String?,
        category: CategoryType,
        location: String?,
        imageUrl: String?,
    ) async throws -> Recommendation {
        print("Supabase: Creating recommendation - Name: '\(name)', Category: \(category.rawValue), City: \(cityId)")

        guard let userId = supabase.auth.currentUser?.id else {
            print("❌ Supabase: No authenticated user found for recommendation creation")
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        print("✅ Supabase: User authenticated - ID: \(userId.uuidString)")

        struct RecommendationInsert: Codable {
            let user_id: String
            let city_id: String
            let name: String
            let description: String?
            let category: String
            let location: String?
            let image_url: String?
        }

        let recommendationData = RecommendationInsert(
            user_id: userId.uuidString,
            city_id: cityId,
            name: name,
            description: description,
            category: category.rawValue,
            location: location,
            image_url: imageUrl,
        )

        print("Supabase: Prepared recommendation data - Image URL: \(imageUrl ?? "none")")

        struct RecommendationResponse: Codable {
            let id: String
            let user_id: String
            let city_id: String
            let name: String
            let description: String?
            let category: String
            let location: String?
            let image_url: String?
        }

        do {
            let response: RecommendationResponse = try await supabase
                .from("recommendations")
                .insert(recommendationData)
                .select()
                .single()
                .execute()
                .value

            print("✅ Supabase: Successfully created recommendation with ID: \(response.id)")

            // Convert the response to a Recommendation object
            let recommendation = Recommendation(
                id: response.id,
                userId: response.user_id,
                cityId: response.city_id,
                category: CategoryType(rawValue: response.category) ?? .other,
                name: response.name,
                description: response.description,
                imageUrl: response.image_url,
                location: response.location,
                avgRating: 0.0, // New recommendations start with 0 rating
                aiSummary: nil,
                summaryUpdatedAt: nil,
            )

            return recommendation

        } catch {
            print("❌ Supabase: Failed to create recommendation - Error: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteRecommendationIfNew(userId _: UUID, spotId: String) async throws {
        struct CommentWithRecId: Codable {
            let rec_id: String
        }

        struct OtherComment: Codable {
            let id: String
        }

        do {
            // First, get the recommendation ID from the comment being deleted
            let commentResponse: [CommentWithRecId] = try await supabase
                .from("comments")
                .select("rec_id")
                .eq("id", value: spotId)
                .execute()
                .value

            guard let recommendationId = commentResponse.first?.rec_id else {
                print("Could not find recommendation ID for comment: \(spotId)")
                return
            }

            // Check if there are ANY other comments on this recommendation (from any user)
            let otherCommentsResponse: [OtherComment] = try await supabase
                .from("comments")
                .select("id")
                .eq("rec_id", value: UUID(uuidString: recommendationId))
                .neq("id", value: UUID(uuidString: spotId))
                .execute()
                .value

            // Only delete the recommendation if no other comments exist
            if otherCommentsResponse.isEmpty {
                try await supabase
                    .from("recommendations")
                    .delete()
                    .eq("id", value: UUID(uuidString: recommendationId))
                    .execute()
            } else {
                print("Other comments exist. Keeping recommendation \(recommendationId)")
            }
        } catch {
            print("error in deleteRecommendationIfNew: \(error.localizedDescription)")
        }
    }

    func getNumCityRatings(cityId: UUID) async throws -> Int {
        let response = try await supabase
            .from("city_reviews")
            .select("id", count: .exact)
            .eq("city_id", value: cityId)
            .execute()
        return response.count ?? 0
    }

    // MARK: - Alert/Notification Functions

    func fetchNotifications(limit: Int = 50) async throws -> [AppNotification] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "NotificationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        struct NotificationResponse: Codable {
            let id: UUID
            let user_id: UUID
            let actor_user_id: UUID
            let type: String
            let created_at: Date
            let read_at: Date?
            let profiles: ActorProfile

            struct ActorProfile: Codable {
                let username: String
                let image_url: String?
                let is_popular: Bool
            }
        }

        let response: [NotificationResponse] = try await supabase
            .from("notifications")
            .select("id, user_id, actor_user_id, type, created_at, read_at, profiles!actor_user_id(username, image_url, is_popular)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response.map { notif in
            AppNotification(
                id: notif.id,
                userId: notif.user_id,
                actorUserId: notif.actor_user_id,
                type: AppNotificationType(rawValue: notif.type) ?? .newFollower,
                createdAt: notif.created_at,
                readAt: notif.read_at,
                actorUsername: notif.profiles.username,
                actorImageUrl: notif.profiles.image_url,
                actorIsPopular: notif.profiles.is_popular
            )
        }
    }

    func fetchUnreadNotificationCount() async throws -> Int {
        guard let userId = supabase.auth.currentUser?.id else {
            return 0
        }

        struct NotificationId: Codable {
            let id: UUID
        }

        let response: [NotificationId] = try await supabase
            .from("notifications")
            .select("id")
            .eq("user_id", value: userId)
            .is("read_at", value: nil)
            .execute()
            .value

        return response.count
    }

    // Mark notification as read
    func markNotificationAsRead(notificationId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["read_at": Date()])
            .eq("id", value: notificationId)
            .execute()
    }

    // Mark all notifications as read
    func markAllNotificationsAsRead() async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }

        try await supabase
            .from("notifications")
            .update(["read_at": Date()])
            .eq("user_id", value: userId)
            .is("read_at", value: nil)
            .execute()
    }

    func createFollowerNotification(followerId: UUID, followingId: UUID) async throws {
        struct NotificationInsert: Encodable {
            let user_id: UUID
            let actor_user_id: UUID
            let type: String
        }

        struct RecentNotification: Decodable {
            let id: UUID
            let created_at: Date
            let type: String
        }

        // Get the most recent notification from this actor to this user
        let recentNotifications: [RecentNotification] = try await supabase
            .from("notifications")
            .select("id, created_at, type")
            .eq("user_id", value: followingId.uuidString.lowercased())
            .eq("actor_user_id", value: followerId.uuidString.lowercased())
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        if let _ = recentNotifications.first {
            print(recentNotifications)
        }

        // Check if the most recent notification is within the cooldown period
        if let mostRecent = recentNotifications.first {
            let timeSinceLastNotification = Date().timeIntervalSince(mostRecent.created_at)
            let cooldownSeconds = TimeInterval(3600) // 1hr cooldown

            if timeSinceLastNotification < cooldownSeconds {
                print("Skipping notification - cooldown active (\(Int(cooldownSeconds - timeSinceLastNotification)) seconds remaining)")
                return
            }
        }

        let notification = NotificationInsert(user_id: followingId, actor_user_id: followerId, type: "new_follower")
        try await supabase.from("notifications").insert(notification).execute()
    }

    // MARK: - SocialView Functions

    func fetchUsers(userId: String) async throws -> [OtherProfile] {
        let response: [OtherProfile] = try await supabase
            .from("profiles")
            .select("id, username, image_url, is_popular, first_name, last_name")
            .notEquals("id", value: userId)
            .execute()
            .value
        return response
    }

    // Fetches activity feed from users that the current user follows
    func fetchFollowingActivityFeed(userId: UUID, limit: Int = 50) async throws -> [FeedItem] {
        // First, get the list of users that the current user follows
        struct Following: Codable {
            let following_id: String
        }

        let followingResponse: [Following] = try await supabase
            .from("followers")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value

        var followingIds = followingResponse.map { $0.following_id }
        followingIds.append(userId.uuidString)

        // If not following anyone, return empty array
        if followingIds.isEmpty {
            return []
        }

        // Fetch city ratings from followed users
        struct CityRatingResponse: Codable {
            let id: String
            let user_id: String
            let city_id: String
            let overall_rating: Double
            let created_at: Date
            let profiles: ProfileData
            let cities: CityData

            struct ProfileData: Codable {
                let username: String
                let image_url: String?
                let is_popular: Bool
            }

            struct CityData: Codable {
                let name: String
                let country: String
                let image_url: String?
            }
        }

        let cityRatings: [CityRatingResponse] = try await supabase
            .from("city_reviews")
            .select("id, user_id, city_id, overall_rating, created_at, profiles!inner(username, image_url, is_popular), cities!inner(name, country, image_url)")
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Fetch spot reviews from followed users
        struct SpotReviewResponse: Codable {
            let id: String
            let user_id: String
            let rec_id: String
            let rating: Int
            let comment: String?
            let image_url: String?
            let created_at: Date
            let profiles: ProfileData
            let rec_with_avg_rating: RecommendationData

            struct ProfileData: Codable {
                let username: String
                let image_url: String?
                let is_popular: Bool
            }

            struct RecommendationData: Codable {
                let id: String
                let name: String
                let category: String
                let description: String?
                let location: String?
                let image_url: String?
                let avg_rating: Double
                let city_id: String
                let cities: CityData

                struct CityData: Codable {
                    let name: String
                    let country: String
                }
            }
        }

        let spotReviews: [SpotReviewResponse] = try await supabase
            .from("comments")
            .select("id, user_id, rec_id, rating, comment, image_url, created_at, profiles!inner(username, image_url, is_popular), rec_with_avg_rating!inner(id, name, category, description, location, image_url, avg_rating, city_id, cities!inner(name, country))")
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Convert city ratings to feed items
        let cityFeedItems: [FeedItem] = cityRatings.map { rating in
            FeedItem(
                id: "\(rating.id)-city",
                type: .cityRating,
                userId: rating.user_id,
                username: rating.profiles.username,
                userImageUrl: rating.profiles.image_url,
                rating: rating.overall_rating,
                createdAt: rating.created_at,
                isUserPopular: rating.profiles.is_popular,
                cityId: rating.city_id,
                cityName: rating.cities.name,
                cityImageUrl: rating.cities.image_url,
                cityCountry: rating.cities.country,
                spotId: nil,
                spotName: nil,
                spotImageUrl: nil,
                commentImageUrl: nil,
                spotCategory: nil,
                spotLocation: nil,
                spotDescription: nil,
                spotAvgRating: nil,
                spotCityCountry: nil,
                reviewComment: nil
            )
        }

        // Convert spot reviews to feed items
        let spotFeedItems: [FeedItem] = spotReviews.map { review in
            FeedItem(
                id: "\(review.id)-spot",
                type: .spotReview,
                userId: review.user_id,
                username: review.profiles.username,
                userImageUrl: review.profiles.image_url,
                rating: Double(review.rating),
                createdAt: review.created_at,
                isUserPopular: review.profiles.is_popular,
                cityId: review.rec_with_avg_rating.city_id,
                cityName: review.rec_with_avg_rating.cities.name,
                cityImageUrl: nil,
                cityCountry: nil,
                spotId: review.rec_id,
                spotName: review.rec_with_avg_rating.name,
                spotImageUrl: review.rec_with_avg_rating.image_url,
                commentImageUrl: review.image_url,
                spotCategory: CategoryType(rawValue: review.rec_with_avg_rating.category),
                spotLocation: review.rec_with_avg_rating.location,
                spotDescription: review.rec_with_avg_rating.description,
                spotAvgRating: review.rec_with_avg_rating.avg_rating,
                spotCityCountry: review.rec_with_avg_rating.cities.country,
                reviewComment: review.comment
            )
        }

        // Combine and sort by date
        let allFeedItems = (cityFeedItems + spotFeedItems).sorted { $0.createdAt > $1.createdAt }

        // Return limited results
        return Array(allFeedItems.prefix(limit))
    }

    // Fetches activity feed from users that are "popular"
    func fetchPopularActivityFeed(limit: Int = 50) async throws -> [FeedItem] {
        // First, get the list of users that are popular
        struct Popular: Codable {
            let popular_id: String

            enum CodingKeys: String, CodingKey {
                case popular_id = "id"
            }
        }

        let popularResponse: [Popular] = try await supabase
            .from("profiles")
            .select("id")
            .eq("is_popular", value: true)
            .execute()
            .value
        let popularIds = popularResponse.map { $0.popular_id }

        // If not following anyone, return empty array
        if popularIds.isEmpty {
            print("empty sorry")
            return []
        }

        // Fetch city ratings from followed users
        struct CityRatingResponse: Codable {
            let id: String
            let user_id: String
            let city_id: String
            let overall_rating: Double
            let created_at: Date
            let profiles: ProfileData
            let cities: CityData

            struct ProfileData: Codable {
                let username: String
                let image_url: String?
                let is_popular: Bool
            }

            struct CityData: Codable {
                let name: String
                let country: String
                let image_url: String?
            }
        }

        let cityRatings: [CityRatingResponse] = try await supabase
            .from("city_reviews")
            .select("id, user_id, city_id, overall_rating, created_at, profiles!inner(username, image_url, is_popular), cities!inner(name, country, image_url)")
            .in("user_id", values: popularIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Fetch spot reviews from followed users
        struct SpotReviewResponse: Codable {
            let id: String
            let user_id: String
            let rec_id: String
            let rating: Int
            let comment: String?
            let image_url: String?
            let created_at: Date
            let profiles: ProfileData
            let rec_with_avg_rating: RecommendationData

            struct ProfileData: Codable {
                let username: String
                let image_url: String?
                let is_popular: Bool
            }

            struct RecommendationData: Codable {
                let id: String
                let name: String
                let category: String
                let description: String?
                let location: String?
                let image_url: String?
                let avg_rating: Double
                let city_id: String
                let cities: CityData

                struct CityData: Codable {
                    let name: String
                    let country: String
                }
            }
        }

        let spotReviews: [SpotReviewResponse] = try await supabase
            .from("comments")
            .select("id, user_id, rec_id, rating, comment, image_url, created_at, profiles!inner(username, image_url, is_popular), rec_with_avg_rating!inner(id, name, category, description, location, image_url, avg_rating, city_id, cities!inner(name, country))")
            .in("user_id", values: popularIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Convert city ratings to feed items
        let cityFeedItems: [FeedItem] = cityRatings.map { rating in
            FeedItem(
                id: "\(rating.id)-city",
                type: .cityRating,
                userId: rating.user_id,
                username: rating.profiles.username,
                userImageUrl: rating.profiles.image_url,
                rating: rating.overall_rating,
                createdAt: rating.created_at,
                isUserPopular: rating.profiles.is_popular,
                cityId: rating.city_id,
                cityName: rating.cities.name,
                cityImageUrl: rating.cities.image_url,
                cityCountry: rating.cities.country,
                spotId: nil,
                spotName: nil,
                spotImageUrl: nil,
                commentImageUrl: nil,
                spotCategory: nil,
                spotLocation: nil,
                spotDescription: nil,
                spotAvgRating: nil,
                spotCityCountry: nil,
                reviewComment: nil
            )
        }

        // Convert spot reviews to feed items
        let spotFeedItems: [FeedItem] = spotReviews.map { review in
            FeedItem(
                id: "\(review.id)-spot",
                type: .spotReview,
                userId: review.user_id,
                username: review.profiles.username,
                userImageUrl: review.profiles.image_url,
                rating: Double(review.rating),
                createdAt: review.created_at,
                isUserPopular: review.profiles.is_popular,
                cityId: review.rec_with_avg_rating.city_id,
                cityName: review.rec_with_avg_rating.cities.name,
                cityImageUrl: nil,
                cityCountry: nil,
                spotId: review.rec_id,
                spotName: review.rec_with_avg_rating.name,
                spotImageUrl: review.rec_with_avg_rating.image_url,
                commentImageUrl: review.image_url,
                spotCategory: CategoryType(rawValue: review.rec_with_avg_rating.category),
                spotLocation: review.rec_with_avg_rating.location,
                spotDescription: review.rec_with_avg_rating.description,
                spotAvgRating: review.rec_with_avg_rating.avg_rating,
                spotCityCountry: review.rec_with_avg_rating.cities.country,
                reviewComment: review.comment
            )
        }

        // Combine and sort by date
        let allFeedItems = (cityFeedItems + spotFeedItems).sorted { $0.createdAt > $1.createdAt }

        // Return limited results
        return Array(allFeedItems.prefix(limit))
    }

    // MARK: - CommentsView Functions

    // fetches all the comments for a given rec
    func fetchComments(for recommendationId: String) async throws -> [Comment] {
        let response: [RatingTemporary] = try await supabase
            .from("comments")
            .select("*, profiles!rec_reviews_user_id_fkey(username)")
            .eq("rec_id", value: recommendationId)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Convert to your Comment struct

        return response.map { review in
            Comment(
                id: review.id,
                userId: review.userId,
                recId: review.recommendationId,
                rating: review.rating,
                comment: review.comment,
                createdAt: review.createdAt,
                imageUrl: review.imageUrl,
                username: review.profiles?.username,
            )
        }
    }

    // submits a comment
    func submitComment(recommendationId: String, text: String?, imageUrl: String?, rating: Double) async throws -> Comment {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct CommentInsert: Codable {
            let user_id: String
            let rec_id: String
            let rating: Double
            let comment: String?
            let created_at: String
            let image_url: String?
        }

        let commentData = CommentInsert(
            user_id: userId.uuidString,
            rec_id: recommendationId,
            rating: rating,
            comment: text,
            created_at: ISO8601DateFormatter().string(from: Date()),
            image_url: imageUrl,
        )

        let response: RatingTemporary = try await supabase
            .from("comments")
            .insert(commentData)
            .select("*, profiles!rec_reviews_user_id_fkey(username)")
            .single()
            .execute()
            .value

        let newComment = Comment(
            id: response.id,
            userId: response.userId,
            recId: response.recommendationId,
            rating: response.rating,
            comment: response.comment,
            createdAt: response.createdAt,
            imageUrl: response.imageUrl,
            username: response.profiles?.username,
        )

        // If comment has an image, check if recommendation needs an image
        if let commentImageUrl = imageUrl {
            try await updateRecommendationImageIfNeeded(recommendationId: recommendationId, imageUrl: commentImageUrl)
        }

        return newComment
    }

    // Helper method to update recommendation image if it doesn't have one
    private func updateRecommendationImageIfNeeded(recommendationId: String, imageUrl: String) async throws {
        // First check if the recommendation already has an image
        struct RecommendationImage: Codable {
            let image_url: String?
        }

        let currentRec: RecommendationImage = try await supabase
            .from("recommendations")
            .select("image_url")
            .eq("id", value: recommendationId)
            .single()
            .execute()
            .value

        // If recommendation doesn't have an image, update it with the comment's image
        if currentRec.image_url == nil || currentRec.image_url?.isEmpty == true {
            try await supabase
                .from("recommendations")
                .update(["image_url": imageUrl])
                .eq("id", value: recommendationId)
                .execute()
        }
    }

    func uploadCommentImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        let fileName = "comment_\(UUID().uuidString).jpg"

        let bucket = supabase.storage.from("comment-images")
        try await bucket.upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        let imageUrl = try bucket.getPublicURL(path: fileName).absoluteString
        return imageUrl
    }

    func uploadRecommendationImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        let fileName = "rec_\(UUID().uuidString).jpg"

        let bucket = supabase.storage.from("comment-images")
        try await bucket.upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        let imageUrl = try bucket.getPublicURL(path: fileName).absoluteString
        return imageUrl
    }

    func getUserRecommendationRating(recommendationId: String) async throws -> Double? {
        guard let userId = supabase.auth.currentUser?.id else {
            return nil
        }

        struct RatingResponse: Decodable {
            let rating: Double
        }

        let response: [RatingResponse] = try await supabase
            .from("comments")
            .select("rating")
            .eq("user_id", value: userId.uuidString)
            .eq("rec_id", value: recommendationId)
            .limit(1)
            .execute()
            .value

        return response.first.map { Double($0.rating) }
    }

    func submitRecommendationRating(recommendationId: String, rating: Double) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct RatingInsert: Codable {
            let rec_id: String
            let user_id: String
            let rating: Double
            let comment: String
        }

        let ratingData = RatingInsert(
            rec_id: recommendationId,
            user_id: userId.uuidString,
            rating: rating,
            comment: ""
        )

        do {
            try await supabase
                .from("comments")
                .insert(ratingData)
                .execute()
        } catch {
            try await supabase
                .from("comments")
                .update(["rating": rating])
                .eq("user_id", value: userId.uuidString)
                .eq("rec_id", value: recommendationId)
                .execute()
        }
    }

    // MARK: - Comment Voting Functions

    // Vote on a comment (upvote or downvote)
    func voteOnComment(commentId: String, voteType: VoteType) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        // First, remove any existing vote by this user on this comment
        try await supabase
            .from("comment_votes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("comment_id", value: commentId)
            .execute()

        // Then insert the new vote1
        struct VoteInsert: Codable {
            let user_id: String
            let comment_id: String
            let vote_type: String
        }

        let voteData = VoteInsert(
            user_id: userId.uuidString,
            comment_id: commentId,
            vote_type: voteType.rawValue
        )

        try await supabase
            .from("comment_votes")
            .insert(voteData)
            .execute()
    }

    // Remove vote from a comment
    func removeVoteFromComment(commentId: String) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        try await supabase
            .from("comment_votes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("comment_id", value: commentId)
            .execute()
    }

    // Fetch comments with vote counts and user's vote status
    func fetchCommentsWithVotes(for recommendationId: String, sortBy: CommentSortOption) async throws -> [Comment] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        // Query your comments_with_votes view
        struct CommentWithVotes: Codable {
            let id: String
            let user_id: String
            let rec_id: String
            let rating: Double
            let comment: String?
            let created_at: Date
            let image_url: String?
            let username: String?
            let upvote_count: Int?
            let downvote_count: Int?
            let net_votes: Int?
        }

        // First get comments with vote counts - build query based on sort option
        let commentsResponse: [CommentWithVotes]

        switch sortBy {
        case .upvotes:
            commentsResponse = try await supabase
                .from("comments_with_votes")
                .select("*")
                .eq("rec_id", value: recommendationId)
                .order("upvote_count", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
        case .recent:
            commentsResponse = try await supabase
                .from("comments_with_votes")
                .select("*")
                .eq("rec_id", value: recommendationId)
                .order("created_at", ascending: false)
                .execute()
                .value
        case .downvotes:
            commentsResponse = try await supabase
                .from("comments_with_votes")
                .select("*")
                .eq("rec_id", value: recommendationId)
                .order("downvote_count", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
        }

        // Get unique user IDs from comments
        let userIds = Array(Set(commentsResponse.map { $0.user_id }))

        // Fetch profile data for all users
        struct ProfileData: Codable {
            let id: String
            let image_url: String?
            let is_popular: Bool?
        }

        let profiles: [ProfileData] = try await supabase
            .from("profiles")
            .select("id, image_url, is_popular")
            .in("id", values: userIds)
            .execute()
            .value

        // Create a lookup dictionary for profiles
        let profilesDict = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        // Get comment IDs for user votes
        let commentIds = commentsResponse.map { $0.id }

        struct UserVote: Codable {
            let comment_id: String
            let vote_type: String
        }

        let userVotes: [UserVote] = try await supabase
            .from("comment_votes")
            .select("comment_id, vote_type")
            .eq("user_id", value: userId.uuidString)
            .in("comment_id", values: commentIds)
            .execute()
            .value

        // Create a lookup dictionary for user votes
        let userVotesDict = Dictionary(uniqueKeysWithValues: userVotes.map { ($0.comment_id, $0.vote_type) })

        return commentsResponse.map { commentData in
            let profile = profilesDict[commentData.user_id]
            return Comment(
                id: commentData.id,
                userId: commentData.user_id,
                recId: commentData.rec_id,
                rating: commentData.rating,
                comment: commentData.comment,
                createdAt: commentData.created_at,
                imageUrl: commentData.image_url,
                username: commentData.username,
                profileImageUrl: profile?.image_url,
                isPopular: profile?.is_popular ?? false,
                upvoteCount: commentData.upvote_count ?? 0,
                downvoteCount: commentData.downvote_count ?? 0,
                netVotes: commentData.net_votes ?? 0,
                userVote: userVotesDict[commentData.id].flatMap { VoteType(rawValue: $0) }
            )
        }
    }

    // MARK: - LoginView Functions

    func fetchEmailWithUsername(username: String) async throws -> String? {
        struct Profile: Codable {
            let email: String?
        }

        let profile: Profile = try await supabase.from("profiles")
            .select("email")
            .ilike("username", pattern: username.lowercased())
            .single()
            .execute()
            .value

        return profile.email
    }

    func isUsernameAvailable(username: String) async throws -> Bool {
        struct Profile: Codable {
            let username: String?
        }

        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select("username")
            .ilike("username", pattern: username.lowercased())
            .execute()
            .value

        return profiles.isEmpty
    }

    func changeUsername(userId: UUID, username: String) async throws {
        print("userId: \(userId)")

        do {
            try await supabase
                .from("profiles")
                .update(["username": username])
                .eq("id", value: userId)
                .execute()
        } catch {
            print("error changing username: \(error.localizedDescription)")
        }
    }

    func changeFirstName(userId: UUID, name: String) async throws {
        do {
            try await supabase
                .from("profiles")
                .update(["first_name": name])
                .eq("id", value: userId)
                .execute()
        } catch {
            print("error changing first name: \(error.localizedDescription)")
        }
    }

    func changeLastName(userId: UUID, name: String) async throws {
        do {
            try await supabase
                .from("profiles")
                .update(["last_name": name])
                .eq("id", value: userId)
                .execute()
        } catch {
            print("error changing last name: \(error.localizedDescription)")
        }
    }

    func changeBio(userId: UUID, bio: String) async throws {
        do {
            try await supabase
                .from("profiles")
                .update(["bio": bio])
                .eq("id", value: userId)
                .execute()
        } catch {
            print("error changing bio: \(error.localizedDescription)")
        }
    }

    func updateFeedDefault(userId: UUID, feedDefault: String) async throws {
        do {
            try await supabase
                .from("profiles")
                .update(["feed_default": feedDefault])
                .eq("id", value: userId)
                .execute()
        } catch {
            print("error updating feed default: \(error.localizedDescription)")
        }
    }

    func saveUserNames(userId: UUID, username: String, firstName: String, lastName: String) async throws {
        try await supabase
            .from("profiles")
            .update([
                "username": username,
                "first_name": firstName,
                "last_name": lastName,
            ])
            .eq("id", value: userId)
            .execute()
    }

    func isEmailAvailable(email: String) async throws -> Bool {
        struct Profile: Codable {
            let email: String?
        }

        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select("email")
            .ilike("email", pattern: email.lowercased())
            .execute()
            .value

        return profiles.isEmpty
    }

    func hasCompletedOnboarding(userId: UUID) async throws -> Bool {
        // Check if user has a username in their profile
        struct UserProfile: Codable {
            let username: String?
        }

        let profileResponse: [UserProfile] = try await supabase
            .from("profiles")
            .select("username")
            .eq("id", value: userId)
            .execute()
            .value

        // User has completed onboarding if they have a username
        guard let profile = profileResponse.first,
              let username = profile.username,
              !username.isEmpty
        else {
            return false
        }

        return true
    }

    // MARK: - ProfileView Functions

    // adds profile image to profile-images bucket and profiles table
    func uploadProfileImageToSupabase(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8), let user = try? await SupabaseManager.shared.supabase.auth.session.user else {
            print("Failed to convert UIImage to jpeg data")
            return
        }

        let fileName = UUID().uuidString + ".jpg"

        Task {
            do {
                let bucket = SupabaseManager.shared.supabase.storage.from("profile-images")
                try await bucket.upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))

                let imageUrl = try bucket.getPublicURL(path: fileName).absoluteString

                try await supabase.from("profiles")
                    .update(["image_url": imageUrl])
                    .eq("id", value: user.id)
                    .execute()

            } catch {
                print("error uploading image: \(error.localizedDescription)")
            }
        }
    }

    // insert username into profiles table after user signup
    func insertUsername(username: String) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        try await supabase.from("profiles")
            .update(["username": username])
            .eq("id", value: userId)
            .execute()
    }

    // fetch username from profiles table by user id
    func fetchUsernameAndNames(userId: UUID) async throws -> [String] {
        struct Profile: Codable {
            let username: String?
            let first_name: String?
            let last_name: String?
        }

        let profile: Profile = try await supabase.from("profiles")
            .select("username, first_name, last_name")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return [profile.username ?? "", profile.first_name ?? "", profile.last_name ?? ""]
    }

    func fetchUserBio(userId: UUID) async throws -> String {
        struct Bio: Codable {
            let bio: String?
        }
        let response: Bio = try await supabase.from("profiles")
            .select("bio")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return response.bio ?? ""
    }

    func fetchFeedDefault(userId: UUID) async throws -> String {
        struct FeedDefault: Codable {
            let feedDefault: String?

            enum CodingKeys: String, CodingKey {
                case feedDefault = "feed_default"
            }
        }
        let response: FeedDefault = try await supabase.from("profiles")
            .select("feed_default")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return response.feedDefault ?? "popular"
    }

    // fetch username from profiles table by user id
    func fetchProfilePic(userId: UUID) async throws -> String {
        struct Profile: Codable {
            let imageURL: String?

            enum CodingKeys: String, CodingKey {
                case imageURL = "image_url"
            }
        }

        let response: PostgrestResponse<Profile> = try await supabase
            .from("profiles")
            .select("image_url")
            .eq("id", value: userId)
            .single()
            .execute()

        let profile = try JSONDecoder().decode(Profile.self, from: response.data)
        return profile.imageURL ?? ""
    }

    // fetch whether or not the user is a "popular creator"
    func fetchIsPopular(userId: UUID) async throws -> Bool {
        struct IsPopular: Codable {
            let isPopular: Bool?

            enum CodingKeys: String, CodingKey {
                case isPopular = "is_popular"
            }
        }
        let response: IsPopular = try await supabase
            .from("profiles")
            .select("is_popular")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return response.isPopular ?? false
    }

    func fetchFollowerCount(userId: UUID) async throws -> (followers: Int, following: Int) {
        struct FollowStats: Codable {
            let followingCount: Int
            let followersCount: Int

            enum CodingKeys: String, CodingKey {
                case followingCount = "following_count"
                case followersCount = "followers_count"
            }
        }

        let stats: FollowStats = try await supabase
            .from("user_follow_stats")
            .select("following_count, followers_count")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        return (followers: stats.followersCount, following: stats.followingCount)
    }

    func fetchIsFollowing(curUserId: UUID, otherUserId: UUID) async throws -> Bool {
        struct FollowRecord: Codable {
            let id: String
        }

        do {
            let response: [FollowRecord] = try await supabase
                .from("followers")
                .select("id")
                .eq("follower_id", value: curUserId)
                .eq("following_id", value: otherUserId)
                .limit(1)
                .execute()
                .value

            return !response.isEmpty
        } catch {
            print("failed to find if following: \(error)")
            return false
        }
    }

    func followUser(followerId: UUID, followingId: UUID) async throws {
        print("supabase following user")
        struct FollowInsert: Codable {
            let follower_id: String
            let following_id: String
        }

        let followData = FollowInsert(
            follower_id: followerId.uuidString,
            following_id: followingId.uuidString
        )

        try await supabase
            .from("followers")
            .insert(followData)
            .execute()
        print("calling createFollowerNotif")
        try await createFollowerNotification(followerId: followerId, followingId: followingId)
    }

    func unfollowUser(followerId: UUID, followingId: UUID) async throws {
        try await supabase
            .from("followers")
            .delete()
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
    }

    func fetchFollowersList(userId: UUID) async throws -> [OtherProfile] {
        struct FollowerWithProfile: Codable {
            let follower_id: String
            let profiles: ProfileInfo
        }

        struct ProfileInfo: Codable {
            let id: String
            let username: String
            let image_url: String?
            let is_popular: Bool
            let first_name: String?
            let last_name: String?
        }

        let response: [FollowerWithProfile] = try await supabase
            .from("followers")
            .select("follower_id, profiles!followers_follower_id_fkey(id, username, image_url, is_popular, first_name, last_name)")
            .eq("following_id", value: userId)
            .execute()
            .value

        return response.map { follower in
            OtherProfile(
                id: UUID(uuidString: follower.profiles.id) ?? UUID(),
                username: follower.profiles.username,
                imageUrl: follower.profiles.image_url,
                isPopular: follower.profiles.is_popular,
                firstName: follower.profiles.first_name,
                lastName: follower.profiles.last_name
            )
        }
    }

    func fetchFollowingList(userId: UUID) async throws -> [OtherProfile] {
        struct FollowingWithProfile: Codable {
            let following_id: String
            let profiles: ProfileInfo
        }

        struct ProfileInfo: Codable {
            let id: String
            let username: String
            let image_url: String?
            let is_popular: Bool
            let first_name: String?
            let last_name: String?
        }

        let response: [FollowingWithProfile] = try await supabase
            .from("followers")
            .select("following_id, profiles!followers_following_id_fkey(id, username, image_url, is_popular, first_name, last_name)")
            .eq("follower_id", value: userId)
            .execute()
            .value

        return response.map { following in
            OtherProfile(
                id: UUID(uuidString: following.profiles.id) ?? UUID(),
                username: following.profiles.username,
                imageUrl: following.profiles.image_url,
                isPopular: following.profiles.is_popular,
                firstName: following.profiles.first_name,
                lastName: following.profiles.last_name
            )
        }
    }

    func fetchUserTravelHistory(userId: UUID) async throws -> [UserRatedCity] {
        struct CityReviewWithCity: Decodable {
            let cityId: UUID
            let overallRating: Double?
            let createdAt: Date?
            let city: CityInfo

            enum CodingKeys: String, CodingKey {
                case cityId = "city_id"
                case overallRating = "overall_rating"
                case createdAt = "created_at"
                case city = "city_with_avg_rating"
            }
        }

        struct CityInfo: Decodable {
            let id: UUID
            let name: String
            let country: String
            let imageUrl: String?
            let avgRating: Double?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case country
                case imageUrl = "image_url"
                case avgRating = "avg_rating"
            }
        }

        let userRatedCities: [CityReviewWithCity] = try await supabase
            .from("city_reviews")
            .select("city_id, overall_rating, created_at, city_with_avg_rating!inner(id, name, country, image_url, avg_rating)")
            .eq("user_id", value: userId)
            .execute()
            .value

        return userRatedCities.map { reviewData in
            UserRatedCity(
                id: reviewData.city.id,
                name: reviewData.city.name,
                country: reviewData.city.country,
                imageUrl: reviewData.city.imageUrl,
                userRating: reviewData.overallRating,
                createdAt: reviewData.createdAt,
                avgRating: reviewData.city.avgRating
            )
        }
    }

    func fetchUserBucketList(userId: UUID) async throws -> [City] {
        struct CityIdRow: Decodable {
            let cityId: UUID

            enum CodingKeys: String, CodingKey {
                case cityId = "city_id"
            }
        }
        let cityIdsResponse: PostgrestResponse<[CityIdRow]> = try await supabase.from("user_bucket_list")
            .select("city_id")
            .eq("user_id", value: userId)
            .execute()

        let cityIds = cityIdsResponse.value.map { $0.cityId }

        let cities: [City] = try await supabase.from("city_with_avg_rating")
            .select()
            .in("id", values: cityIds)
            .execute()
            .value
        return cities
    }

    func fetchTravelStats(userId: UUID) async throws -> TravelStats {
        let stats: [TravelStats] = try await supabase
            .from("user_travel_stats")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value

        return stats.first ?? TravelStats(userId: userId.uuidString, countriesVisited: 0, citiesVisited: 0, spotsVisited: 0)
    }

    struct TravelStats: Codable {
        let userId: String
        let countriesVisited: Int
        let citiesVisited: Int
        let spotsVisited: Int

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case countriesVisited = "countries_visited"
            case citiesVisited = "cities_visited"
            case spotsVisited = "spots_visited"
        }
    }

    func fetchNumCitiesVisited(userId: UUID) async throws -> Int {
        let response = try await supabase.from("city_reviews")
            .select("id", count: .exact)
            .eq("user_id", value: userId)
            .execute()

        return response.count ?? 0
    }

    func fetchNumRecsSubmitted(userId: UUID) async throws -> Int {
        let num = try await supabase.from("comments")
            .select("id", count: .exact)
            .eq("user_id", value: userId)
            .execute()
        return num.count ?? 0
    }

    func deleteSpotComment(commentId: String) async throws {
        do {
            try await supabase.from("comments")
                .delete()
                .eq("id", value: commentId)
                .execute()
        } catch {
            print("supabase delete spot error: \(error.localizedDescription)")
        }
    }

    // MARK: - CityDetailView Functions
    
    // recalculate the avg rating for a city
    func reloadAvgRating(cityId: UUID) async throws -> Double? {
        struct RatingResponse: Decodable {
            let avg_rating: Double?
        }

        let avgRating: RatingResponse = try await supabase.from("city_with_avg_rating")
            .select("avg_rating")
            .eq("id", value: cityId)
            .single()
            .execute()
            .value
        
        return avgRating.avg_rating
    }

    // get the rating of a specific city from a specific user
    func getCityRatingForUser(cityId: UUID, userId: UUID) async throws -> Double? {
        struct RatingResponse: Decodable {
            let overall_rating: Double?
        }

        let response: PostgrestResponse = try await supabase.from("city_reviews")
            .select("overall_rating")
            .eq("user_id", value: userId)
            .eq("city_id", value: cityId)
            .execute()

        // Decode the response as an array of RatingResponse
        let ratings = try JSONDecoder().decode([RatingResponse].self, from: response.data)

        // Return the only rating if one exists, else nil
        return ratings.first?.overall_rating
    }

    // adds or updates a review for a city
    func addCityReview(userId: UUID, cityId: UUID, rating: Double) async throws {
        guard supabase.auth.currentUser?.id != nil else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        // Try to insert a new review
        let review = CityReviewModel(cityId: cityId.uuidString, userId: userId.uuidString, rating: rating)

        do {
            try await supabase
                .from("city_reviews")
                .insert(review)
                .execute()
        } catch {
            // If insert fails (likely due to duplicate), update only the rating to preserve created_at
            try await supabase
                .from("city_reviews")
                .update(["overall_rating": rating])
                .eq("city_id", value: cityId)
                .eq("user_id", value: userId)
                .execute()
        }
    }

    // deletes a city review for a user
    func deleteCityReview(userId: UUID, cityId: UUID) async throws {
        do {
            print("in supabase, userId: \(userId) and cityId: \(cityId)")
            try await supabase
                .from("city_reviews")
                .delete()
                .eq("city_id", value: cityId)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("error deleting city rating: \(error.localizedDescription)")
        }
    }

    func getIsCityFavorite(cityId: UUID, userId: UUID) async throws -> Bool {
        struct Favorite: Codable {
            let city_id: UUID
        }

        let response: [Favorite] = try await SupabaseManager.shared.supabase
            .from("user_bucket_list")
            .select("city_id")
            .eq("user_id", value: userId)
            .eq("city_id", value: cityId)
            .limit(1)
            .execute()
            .value

        return !response.isEmpty
    }

    // remove a city from bucket list
    func removeUserFavoriteCity(userId: UUID, cityId: UUID) async throws {
        try await supabase.from("user_bucket_list")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("city_id", value: cityId.uuidString)
            .execute()
    }

    // add a city to bucket list
    func addUserFavoriteCity(userId: UUID, cityId: UUID) async throws {
        try await supabase.from("user_bucket_list")
            .insert(["user_id": userId.uuidString, "city_id": cityId.uuidString])
            .execute()
    }

    // MARK: - User Preferences Functions

    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct UserPreferencesInsert: Codable {
            let user_id: String
            let energy_level: String
            let social_preference: String
            let time_preference: String
            let budget_range: String
            let activity_preferences: [String: String]
            let max_walking_distance: String
            let transportation_preference: String
            let accommodation_style: String
            let planning_style: String
            let risk_tolerance: String
            let cultural_immersion: String
            let crowd_tolerance: String
        }

        // Convert activity preferences to dictionary
        var activityPrefsDict: [String: String] = [:]
        for (activity, level) in preferences.activityPreferences.preferences {
            activityPrefsDict[activity.rawValue] = level.rawValue
        }

        let preferencesData = UserPreferencesInsert(
            user_id: userId.uuidString,
            energy_level: preferences.travelStyle.energyLevel.rawValue,
            social_preference: preferences.travelStyle.socialPreference.rawValue,
            time_preference: preferences.travelStyle.timePreference.rawValue,
            budget_range: preferences.travelStyle.budgetRange.rawValue,
            activity_preferences: activityPrefsDict,
            max_walking_distance: preferences.practicalPreferences.maxWalkingDistance.rawValue,
            transportation_preference: preferences.practicalPreferences.transportationPreference.rawValue,
            accommodation_style: preferences.practicalPreferences.accommodationStyle.rawValue,
            planning_style: preferences.additionalPreferences.planningStyle.rawValue,
            risk_tolerance: preferences.additionalPreferences.riskTolerance.rawValue,
            cultural_immersion: preferences.additionalPreferences.culturalImmersion.rawValue,
            crowd_tolerance: preferences.additionalPreferences.crowdTolerance.rawValue
        )

        do {
            // Try to insert new preferences
            try await supabase
                .from("user_preferences")
                .insert(preferencesData)
                .execute()

            print("✅ User preferences saved successfully")

        } catch {
            // If insert fails (user already has preferences), update existing record
            let activityPrefsJsonData = try JSONSerialization.data(withJSONObject: preferencesData.activity_preferences)
            let activityPrefsJsonString = String(data: activityPrefsJsonData, encoding: .utf8) ?? "{}"

            try await supabase
                .from("user_preferences")
                .update([
                    "energy_level": preferencesData.energy_level,
                    "social_preference": preferencesData.social_preference,
                    "time_preference": preferencesData.time_preference,
                    "budget_range": preferencesData.budget_range,
                    "activity_preferences": activityPrefsJsonString,
                    "max_walking_distance": preferencesData.max_walking_distance,
                    "transportation_preference": preferencesData.transportation_preference,
                    "accommodation_style": preferencesData.accommodation_style,
                    "planning_style": preferencesData.planning_style,
                    "risk_tolerance": preferencesData.risk_tolerance,
                    "cultural_immersion": preferencesData.cultural_immersion,
                    "crowd_tolerance": preferencesData.crowd_tolerance,
                    "updated_at": ISO8601DateFormatter().string(from: Date()),
                ])
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("User preferences updated successfully")
        }
    }

    func fetchUserPreferences() async throws -> UserPreferences? {
        guard let userId = supabase.auth.currentUser?.id else {
            return nil
        }

        struct UserPreferencesResponse: Codable {
            let id: String
            let user_id: String
            let energy_level: String
            let social_preference: String
            let time_preference: String
            let budget_range: String
            let activity_preferences: [String: String]
            let max_walking_distance: String
            let transportation_preference: String
            let accommodation_style: String
            let planning_style: String
            let risk_tolerance: String
            let cultural_immersion: String
            let crowd_tolerance: String
            let created_at: String
            let updated_at: String
        }

        let response: [UserPreferencesResponse] = try await supabase
            .from("user_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let prefsData = response.first else {
            return nil
        }

        // Convert response to UserPreferences model
        var preferences = UserPreferences(userId: userId)
        preferences.travelStyle.energyLevel = TravelStylePreferences.EnergyLevel(rawValue: prefsData.energy_level) ?? .balanced
        preferences.travelStyle.socialPreference = TravelStylePreferences.SocialPreference(rawValue: prefsData.social_preference) ?? .flexible
        preferences.travelStyle.timePreference = TravelStylePreferences.TimePreference(rawValue: prefsData.time_preference) ?? .flexible
        preferences.travelStyle.budgetRange = TravelStylePreferences.BudgetRange(rawValue: prefsData.budget_range) ?? .moderate

        // Convert activity preferences back from dictionary
        for (activityKey, levelValue) in prefsData.activity_preferences {
            if let activity = ActivityPreferences.ActivityType(rawValue: activityKey),
               let level = ActivityPreferences.PreferenceLevel(rawValue: levelValue)
            {
                preferences.activityPreferences.preferences[activity] = level
            }
        }

        preferences.practicalPreferences.maxWalkingDistance = PracticalPreferences.WalkingDistance(rawValue: prefsData.max_walking_distance) ?? .moderate
        preferences.practicalPreferences.transportationPreference = PracticalPreferences.TransportationPreference(rawValue: prefsData.transportation_preference) ?? .flexible
        preferences.practicalPreferences.accommodationStyle = PracticalPreferences.AccommodationStyle(rawValue: prefsData.accommodation_style) ?? .flexible

        preferences.additionalPreferences.planningStyle = AdditionalPreferences.PlanningStyle(rawValue: prefsData.planning_style) ?? .structured
        preferences.additionalPreferences.riskTolerance = AdditionalPreferences.RiskTolerance(rawValue: prefsData.risk_tolerance) ?? .moderate
        preferences.additionalPreferences.culturalImmersion = AdditionalPreferences.CulturalImmersion(rawValue: prefsData.cultural_immersion) ?? .moderate
        preferences.additionalPreferences.crowdTolerance = AdditionalPreferences.CrowdTolerance(rawValue: prefsData.crowd_tolerance) ?? .moderate

        // Set timestamps
        let dateFormatter = ISO8601DateFormatter()
        preferences.updatedAt = dateFormatter.date(from: prefsData.updated_at) ?? Date()

        return preferences
    }

    // MARK: - City Request Function

    func requestCity(userId: UUID, cityName: String, country: String) async throws {
        struct CityRequest: Codable {
            let user_id: UUID
            let city_name: String
            let country_name: String
        }

        let cityRequest = CityRequest(user_id: userId, city_name: cityName, country_name: country)

        try await supabase
            .from("city_requests")
            .insert(cityRequest)
            .execute()
    }

    // MARK: - Future Features (Untested)

    // EVERYTHING UNDERNEATH THIS COMMENT HAS NOT BEEN TESTED YET, I HAVE NO CLUE IF THEY WORK (but i feel like they mostly should)

    // fetches the itineraries for a given city
    func fetchItineraries(cityId: UUID) async throws -> [Itinerary] {
        let itineraries: [Itinerary] = try await supabase.from("itineraries")
            .select()
            .eq("city_id", value: cityId.uuidString)
            .execute()
            .value
        return itineraries
    }

    // fetches each item for a given itinerary, need to figure out in the vm how to order these to be able to show a pretty itinerary
    func fetchItineraryItem(itineraryId: UUID) async throws -> [ItineraryItem] {
        let items: [ItineraryItem] = try await supabase.from("itinerary_items")
            .select()
            .eq("itinerary_id", value: itineraryId.uuidString)
            .execute()
            .value
        return items
    }

    // fetches all recommendations that a user has reviewed/rated
    func fetchUserReviewedSpots(userId: UUID) async throws -> [ReviewedSpot] {
        struct ReviewedSpotResponse: Codable {
            let id: String
            let rec_id: String
            let rating: Int
            let comment: String?
            let created_at: Date
            let rec_with_avg_rating: RecommendationWithCityName

            var cityName: String {
                return rec_with_avg_rating.cities.name
            }

            var country: String {
                return rec_with_avg_rating.cities.country
            }

            enum CodingKeys: String, CodingKey {
                case id
                case rec_id
                case rating
                case comment
                case created_at
                case rec_with_avg_rating
            }
        }

        struct RecommendationWithCityName: Codable {
            let id: String
            let name: String
            let category: CategoryType
            let imageUrl: String?
            let location: String?
            let avgRating: Double
            let cities: CityNameOnly

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case category
                case imageUrl = "image_url"
                case location
                case avgRating = "avg_rating"
                case cities
            }
        }

        struct CityNameOnly: Codable {
            let name: String
            let country: String
        }

        let response: [ReviewedSpotResponse] = try await supabase
            .from("comments")
            .select("id, rec_id, rating, comment, created_at, rec_with_avg_rating!inner(*, cities!inner(name, country))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { item in
            let recommendation = Recommendation(
                id: item.rec_with_avg_rating.id,
                userId: "", // Not needed for display
                cityId: "", // Not needed for display
                category: item.rec_with_avg_rating.category,
                name: item.rec_with_avg_rating.name,
                description: nil, // Not available in this query
                imageUrl: item.rec_with_avg_rating.imageUrl,
                location: item.rec_with_avg_rating.location,
                avgRating: item.rec_with_avg_rating.avgRating,
                aiSummary: nil
            )
            return ReviewedSpot(commentId: item.id, recommendation: recommendation, comment: item.comment, userRating: Double(item.rating), cityName: item.cityName, country: item.country, createdAt: item.created_at)
        }
    }

    func fetchUserReviewedSpotsWithVotes(userId: UUID) async throws -> [ReviewedSpot] {
        guard let currentUserId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct ReviewedSpotWithVotesResponse: Codable {
            let id: String
            let rec_id: String
            let rating: Double
            let comment: String?
            let created_at: Date
            let upvote_count: Int?
            let downvote_count: Int?
            let net_votes: Int?
            let rec_with_avg_rating: RecommendationWithCityName

            var cityName: String {
                return rec_with_avg_rating.cities.name
            }

            var country: String {
                return rec_with_avg_rating.cities.country
            }

            enum CodingKeys: String, CodingKey {
                case id
                case rec_id
                case rating
                case comment
                case created_at
                case upvote_count
                case downvote_count
                case net_votes
                case rec_with_avg_rating
            }
        }

        struct RecommendationWithCityName: Codable {
            let id: String
            let name: String
            let category: CategoryType
            let imageUrl: String?
            let location: String?
            let avgRating: Double
            let cities: CityNameOnly

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case category
                case imageUrl = "image_url"
                case location
                case avgRating = "avg_rating"
                case cities
            }
        }

        struct CityNameOnly: Codable {
            let name: String
            let country: String
        }

        let response: [ReviewedSpotWithVotesResponse] = try await supabase
            .from("comments_with_votes")
            .select("id, rec_id, rating, comment, created_at, upvote_count, downvote_count, net_votes, rec_with_avg_rating!inner(*, cities!inner(name, country))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        struct UserVote: Codable {
            let comment_id: String
            let vote_type: String
        }

        let userVotes: [UserVote] = try await supabase
            .from("comment_votes")
            .select("comment_id, vote_type")
            .eq("user_id", value: currentUserId.uuidString)
            .execute()
            .value

        let voteMap = Dictionary(uniqueKeysWithValues: userVotes.map { ($0.comment_id, $0.vote_type) })

        return response.map { item in
            let recommendation = Recommendation(
                id: item.rec_with_avg_rating.id,
                userId: "",
                cityId: "",
                category: item.rec_with_avg_rating.category,
                name: item.rec_with_avg_rating.name,
                description: nil,
                imageUrl: item.rec_with_avg_rating.imageUrl,
                location: item.rec_with_avg_rating.location,
                avgRating: item.rec_with_avg_rating.avgRating,
                aiSummary: nil
            )

            let userVote: VoteType? = voteMap[item.id].flatMap { VoteType(rawValue: $0) }

            return ReviewedSpot(
                commentId: item.id,
                recommendation: recommendation,
                comment: item.comment,
                userRating: Double(item.rating),
                cityName: item.cityName,
                country: item.country,
                createdAt: item.created_at,
                upvoteCount: item.upvote_count ?? 0,
                downvoteCount: item.downvote_count ?? 0,
                netVotes: item.net_votes ?? 0,
                userVote: userVote
            )
        }
    }

    // MARK: - Account Management Functions

    func deleteUserAccount() async throws {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active session found"])
        }

        // Call Supabase Edge Function to delete user account
        // The Edge Function has service role access to delete from both profiles table and auth
        guard let baseURL = URL(string: ConfigManager.shared.supabaseURL) else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL"])
        }
        let url = baseURL.appendingPathComponent("functions/v1/delete-user-account")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(ConfigManager.shared.supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            if httpResponse.statusCode == 200 {
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete account: \(errorMessage)"])
            }
        } catch {
            throw error
        }
    }
}
