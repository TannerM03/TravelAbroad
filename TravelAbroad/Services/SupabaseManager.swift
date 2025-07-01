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

    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://tyttgzrqntyzehfufeqx.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5dHRnenJxbnR5emVoZnVmZXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MjIzNDEsImV4cCI6MjA2Mjk5ODM0MX0.B_kWPnoSjiENKIfggFqMWzdu_vdnKML1gJmzVy4NCcs"
    )

    // fetches the cities to be displayed as travel options,
    func fetchCities() async throws -> [City] {
        let cities: [City] = try await supabase.from("city_with_avg_rating")
            .select()
            .execute()
            .value
        return cities
    }
    
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
    
    //adds profile image to profile-images bucket and profiles table
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
                
                print("Uploaded image successfully")
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

    // EVERYTHING UNDERNEATH THIS COMMENT HAS NOT BEEN TESTED YET, I HAVE NO CLUE IF THEY WORK (but i feel like they mostly should)
    
    // get the rating of a specific city from a specific user
    func getCityRatingForUser(cityId: UUID, userId: UUID) async throws -> Double? {
        struct RatingResponse: Decodable {
            let overall_rating: Double?
        }
        let response: PostgrestResponse<RatingResponse> = try await supabase.from("city_reviews")
            .select("overall_rating")
            .eq("user_id", value: userId)
            .eq("city_id", value: cityId)
            .single()
            .execute()

        let rating = try JSONDecoder().decode(RatingResponse.self, from: response.data)
        print("rating for user: \(rating.overall_rating ?? 0.0)")
        return rating.overall_rating
    }
    
    func fetchUserTravelHistory(userId: UUID) async throws -> [City] {
        struct CityIdRow: Decodable {
            let cityId: UUID
            
            enum CodingKeys: String, CodingKey {
                case cityId = "city_id"
            }
        }
        let cityIdsResponse: PostgrestResponse<[CityIdRow]> = try await supabase.from("city_reviews")
            .select("city_id")
            .eq("user_id", value: userId)
            .execute()
        
        let cityIds = cityIdsResponse.value.map { $0.cityId }
        print("user has reviewed cities: \(cityIds)")
        
        let cities: [City] = try await supabase.from("city_with_avg_rating")
            .select()
            .in("id", values: cityIds)
            .execute()
            .value
        print("supabase cities: \(cities)")
        return cities
    }
    

    // fetches the overall reviews for each city (this is how i will calculator avg review for each city to be displayed on main page
    // not sure if i actually need this
//    func fetchCityReviews(cityId: UUID) async throws -> [CityReviewModel] {
//        let reviews: [CityReviewModel] = try await supabase.from("city_reviews")
//            .select()
//            .eq("city_id", value: cityId.uuidString)
//            .execute()
//            .value
//        return reviews
//    }

    // fetches all of the reviews of a specific recommended place (this is how i will calculate the avg rating for a restaurant, etc.)
    func fetchRecReviews(recId: UUID) async throws -> [RecReview] {
        let reviews: [RecReview] = try await supabase.from("rec_reviews")
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
    
    //adds or updates a review for a city
    func addCityReview(userId: UUID, cityId: UUID, rating: Double) async throws {
        guard let currentUserId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "SupabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        let review: CityReviewModel = CityReviewModel(cityId: cityId.uuidString, userId: userId.uuidString, rating: rating)
        
        let response = try await supabase
            .from("city_reviews")
            .upsert(review,
                    onConflict: "user_id,city_id")
            .execute()
        
        print(response)
        print("status: \(response.status)")
        print("response data: \(String(describing: response.data))")
        
    }


}
