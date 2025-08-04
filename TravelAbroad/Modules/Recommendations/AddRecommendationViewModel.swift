//
//  AddRecommendationViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/3/25.
//

import Foundation

@MainActor
class AddRecommendationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var googlePlaceId: String? = nil
    @Published var searchTask: Task<Void, Never>?
    @Published var searchText: String = ""
    @Published var selectedPlace: GooglePlacesManager.PlaceResult?
    @Published var description = ""
    @Published var isSearching = false
    @Published var searchResults: [GooglePlacesManager.PlaceResult] = []
    @Published var isSubmitting = false
    @Published var userRating: Int = 0
    @Published var showDuplicateAlert = false
    @Published var showNoRatingAlert = false

    // Properties from AddRecommendationView
    let cityId: String
    let cityName: String
    let selectedCategory: CategoryType
    let cityCoordinates: (Double, Double)
    var dismiss: (() -> Void)?

    private let placesManager = GooglePlacesManager.shared
    private let supabaseManager = SupabaseManager.shared

    init(cityId: String, cityName: String, selectedCategory: CategoryType, cityCoordinates: (Double, Double)) {
        self.cityId = cityId
        self.cityName = cityName
        self.selectedCategory = selectedCategory
        self.cityCoordinates = cityCoordinates
    }

    // Core search logic
    func performSearch(query: String, showLoading: Bool) async {
        guard !query.isEmpty else {
            print("AddRecommendation: Search text is empty, skipping search")
            searchResults = []
            if showLoading { isSearching = false }
            return
        }

        if showLoading {
            isSearching = true
        }

        print("🔍 AddRecommendation: Starting place search for: '\(query)'")

        do {
            let categoryQuery = "\(query) \(getCategorySearchTerm())"

            // Use city coordinates if available, otherwise nil for global search
            let coordinates: (Double, Double)? = (cityCoordinates.0 != 0.0 && cityCoordinates.1 != 0.0) ? cityCoordinates : nil

            if let coords = coordinates {
                print("🌍 AddRecommendation: Using location-based search within 100 miles of \(cityName) (\(coords.0), \(coords.1))")
            } else {
                print("⚠️ AddRecommendation: No valid coordinates for \(cityName), using global search")
            }

            let results = try await GooglePlacesManager.shared.searchPlaces(
                query: categoryQuery,
                coordinates: coordinates
            )

            searchResults = Array(results.prefix(5)) // Limit to 5 results
            if showLoading { isSearching = false }
            print("✅ AddRecommendation: Search completed, found \(searchResults.count) results")
        } catch {
            if showLoading { isSearching = false }
            print("❌ AddRecommendation: Error searching places: \(error)")
        }
    }

    // Immediate search (button tap or Enter key)
    func searchPlacesImmediately() async {
        searchTask?.cancel()
        await performSearch(query: searchText, showLoading: true)
    }

    // Legacy method for compatibility
    func searchPlaces() {
        Task {
            await performSearch(query: searchText, showLoading: true)
        }
    }

    func submitRecommendation() {
        guard let place = selectedPlace else {
            print("❌ AddRecommendation: No place selected for submission")
            return
        }

        // Check if user has selected a rating
        guard userRating > 0 else {
            print("⚠️ AddRecommendation: No rating selected")
            showNoRatingAlert = true
            return
        }

        print("AddRecommendation: Submitting recommendation for place: '\(place.name)'")
        print("AddRecommendation: City: \(cityName), Category: \(selectedCategory.rawValue)")
        print("AddRecommendation: Description: '\(description.isEmpty ? "none" : description)'")

        isSubmitting = true

        Task {
            do {
                // Check if this place already exists in the database
                print("🔍 AddRecommendation: Checking for existing recommendation with Google Place ID: \(place.placeId)")

                let existingRecId = try await SupabaseManager.shared.getPlaceIdWithGooglePlaceId(id: place.placeId)

                if let existingId = existingRecId {
                    // Place already exists, show alert to user
                    print("⚠️ AddRecommendation: Place already exists with recommendation ID: \(existingId)")

                    isSubmitting = false
                    showDuplicateAlert = true
                    return
                }

                // Place doesn't exist, create new recommendation
                print("✅ AddRecommendation: No existing recommendation found, creating new one")

                let imageUrl = GooglePlacesManager.shared.getFirstPhotoURL(from: place)
                print("AddRecommendation: Image URL obtained: \(imageUrl ?? "none")")

                let recommendation = try await SupabaseManager.shared.createRecommendation(
                    cityId: cityId,
                    name: place.name,
                    description: nil,
                    category: selectedCategory,
                    location: place.formattedAddress,
                    imageUrl: imageUrl,
                    googlePlaceId: place.placeId
                )

                // Add the user's rating and comment to the newly created recommendation
                let _ = try await supabaseManager.submitComment(
                    recommendationId: recommendation.id,
                    text: description.isEmpty ? nil : description,
                    imageUrl: nil,
                    rating: userRating
                )

                isSubmitting = false
                print("✅ AddRecommendation: Successfully created recommendation with ID: \(recommendation.id) and added rating")
                dismiss?()
            } catch {
                isSubmitting = false
                print("❌ AddRecommendation: Error creating recommendation: \(error.localizedDescription)")
            }
        }
    }

    func getCategorySearchTerm() -> String {
        switch selectedCategory {
        case .restaurants:
            return "restaurant"
        case .hostels:
            return "hotel"
        case .activities:
            return "activity"
        case .nightlife:
            return "bar"
        case .sights:
            return "attraction"
        case .other:
            return ""
        }
    }
}
