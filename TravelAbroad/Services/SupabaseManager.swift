//
//  SupabaseManager.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/1/25.
//

import Foundation
import Supabase

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

    // EVERYTHING UNDERNEATH THIS COMMENT HAS NOT BEEN TESTED YET, I HAVE NO CLUE IF THEY WORK (but i feel like they mostly should)

    // fetches the overall reviews for each city (this is how i will calculator avg review for each city to be displayed on main page
    // not sure if i actually need this
    func fetchCityReviews(cityId: UUID) async throws -> [CityReview] {
        let reviews: [CityReview] = try await supabase.from("city_reviews")
            .select()
            .eq("city_id", value: cityId.uuidString)
            .execute()
            .value
        return reviews
    }

    // fetches the recommended place (restaurants, hostels, bars, etc.) for whichever city is specified in with the cityId parameter
    func fetchRecommendations(cityId: UUID) async throws -> [Recommendation] {
        let recs: [Recommendation] = try await supabase
            .from("recommendations_with_avg_rating")
            .select()
            .eq("city_id", value: cityId)
            .execute()
            .value
        return recs
    }

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
}
