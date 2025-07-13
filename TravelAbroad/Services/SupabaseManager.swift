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
            let cityReviews: [UserReview]?
            
            enum CodingKeys: String, CodingKey {
                case id
                case name
                case country
                case imageUrl = "image_url"
                case avgRating = "avg_rating"
                case cityReviews = "city_reviews"
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
            .select("*, city_reviews!left(overall_rating)")
            .eq("city_reviews.user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response.map { cityData in
            City(id: cityData.id, name: cityData.name, country: cityData.country, imageUrl: cityData.imageUrl, avgRating: cityData.avgRating, userRating: cityData.cityReviews?.first?.overallRating)
        }
    }

    // MARK: - RecommendationsView Functions

    // fetches the recommended place (restaurants, hostels, bars, etc.) for whichever city is specified in with the cityId parameter. Also has avg rating
    func fetchRecommendations(cityId: UUID) async throws -> [Recommendation] {
        let recs: [Recommendation] = try await supabase
            .from("recommendations_with_avg_rating")
            .select()
            .eq("city_id", value: cityId)
            .execute()
            .value
        return recs
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
    func submitComment(recommendationId: String, text: String?, imageUrl: String?, rating: Int) async throws -> Comment {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct CommentInsert: Codable {
            let user_id: String
            let rec_id: String
            let rating: Int
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

        return newComment
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

    func getUserRecommendationRating(recommendationId: String) async throws -> Double? {
        guard let userId = supabase.auth.currentUser?.id else {
            return nil
        }

        struct RatingResponse: Decodable {
            let rating: Int
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

    func submitRecommendationRating(recommendationId: String, rating: Int) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        struct RatingInsert: Codable {
            let rec_id: String
            let user_id: String
            let rating: Int
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
    func fetchUsername(userId: UUID) async throws -> String {
        struct Profile: Codable {
            let username: String?
        }

        let profile: Profile = try await supabase.from("profiles")
            .select("username")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return profile.username ?? ""
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
                case city = "cities"
            }
        }

        struct CityInfo: Decodable {
            let id: UUID
            let name: String
            let country: String
            let imageUrl: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case country
                case imageUrl = "image_url"
            }
        }

        let userRatedCities: [CityReviewWithCity] = try await supabase
            .from("city_reviews")
            .select("city_id, overall_rating, created_at, cities!inner(id, name, country, image_url)")
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
                createdAt: reviewData.createdAt
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

    // MARK: - CityDetailView Functions

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

    // MARK: - Future Features (Untested)

    // EVERYTHING UNDERNEATH THIS COMMENT HAS NOT BEEN TESTED YET, I HAVE NO CLUE IF THEY WORK (but i feel like they mostly should)

    // fetches all of the reviews of a specific recommended place (this is how i will calculate the avg rating for a restaurant, etc.)
    func fetchRecReviews(recId: UUID) async throws -> [Comment] {
        let reviews: [Comment] = try await supabase.from("comments")
            .select()
            .eq("rec_id", value: recId.uuidString)
            .execute()
            .value
        return reviews
    }

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
}
