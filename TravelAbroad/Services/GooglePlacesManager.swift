//
//  GooglePlacesManager.swift
//  TravelAbroad
//
//  Google Places API integration for fetching place data and images
//

import Foundation
import UIKit

class GooglePlacesManager {
    static let shared = GooglePlacesManager()

    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/place"

    private init() {
        apiKey = ConfigManager.shared.googlePlacesAPIKey
    }

    // MARK: - Data Models

    struct PlaceSearchResponse: Codable {
        let results: [PlaceResult]
        let status: String
    }

    struct PlaceResult: Codable, Identifiable {
        let id = UUID()
        let placeId: String
        let name: String
        let formattedAddress: String?
        let rating: Double?
        let priceLevel: Int?
        let types: [String]
        let geometry: Geometry?
        let photos: [PhotoReference]?

        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name
            case formattedAddress = "formatted_address"
            case rating
            case priceLevel = "price_level"
            case types
            case geometry
            case photos
        }
    }

    struct Geometry: Codable {
        let location: Location
    }

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }

    struct PhotoReference: Codable {
        let photoReference: String
        let height: Int
        let width: Int

        enum CodingKeys: String, CodingKey {
            case photoReference = "photo_reference"
            case height
            case width
        }
    }

    struct PlaceDetailsResponse: Codable {
        let result: PlaceDetails
        let status: String
    }

    struct PlaceDetails: Codable {
        let placeId: String
        let name: String
        let formattedAddress: String?
        let rating: Double?
        let photos: [PhotoReference]?
        let types: [String]
        let geometry: Geometry?

        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name
            case formattedAddress = "formatted_address"
            case rating
            case photos
            case types
            case geometry
        }
    }

    // MARK: - API Methods

    func searchPlaces(query: String, coordinates: (Double, Double)?) async throws -> [PlaceResult] {
        print("GooglePlaces: Starting place search for query: '\(query)', coordinates: \(coordinates?.0 ?? 0.0),\(coordinates?.1 ?? 0.0)")

        var urlComponents = URLComponents(string: "\(baseURL)/textsearch/json")!

        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "type", value: "establishment"),
        ]

        if let coords = coordinates {
            // Validate coordinates are within reasonable bounds
            guard coords.0 >= -90, coords.0 <= 90, coords.1 >= -180, coords.1 <= 180 else {
                print("❌ GooglePlaces: Invalid coordinates: \(coords.0), \(coords.1)")
                throw GooglePlacesError.invalidCoordinates
            }

            let locationString = "\(coords.0),\(coords.1)"
            queryItems.append(URLQueryItem(name: "location", value: locationString))
            queryItems.append(URLQueryItem(name: "radius", value: "160934")) // 100 miles in meters
            print("GooglePlaces: Using location-based search with radius 100 miles at \(locationString)")
        } else {
            print("GooglePlaces: No coordinates provided, using global search")
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            print("❌ GooglePlaces: Failed to create URL from components")
            throw GooglePlacesError.invalidURL
        }

        // Mask the API key in the logged URL for security
        let logURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "***MASKED_API_KEY***")
        print("GooglePlaces: Making request to: \(logURL)")

        // Additional diagnostic info
        print("GooglePlaces: Request details - Query: '\(query)', Type: establishment")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ GooglePlaces: Invalid HTTP response")
                throw GooglePlacesError.networkError
            }

            print("GooglePlaces: HTTP Status Code: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                print("❌ GooglePlaces: HTTP Error - Status Code: \(httpResponse.statusCode)")
                throw GooglePlacesError.networkError
            }

            let searchResponse = try JSONDecoder().decode(PlaceSearchResponse.self, from: data)
            print("GooglePlaces: API Response Status: \(searchResponse.status)")

            // Log additional response info for REQUEST_DENIED debugging
            if searchResponse.status == "REQUEST_DENIED" {
                print("🚨 GooglePlaces: REQUEST_DENIED - This usually means:")
                print("   • API key is missing or invalid")
                print("   • Places API is not enabled in Google Cloud Console")
                print("   • Billing is not set up")
                print("   • API key restrictions are blocking the request")
                print("   • Bundle ID doesn't match API key restrictions")

                // Log the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 GooglePlaces: Raw API Response: \(responseString)")
                }
            }

            guard searchResponse.status == "OK" || searchResponse.status == "ZERO_RESULTS" else {
                print("❌ GooglePlaces: API Error - Status: \(searchResponse.status)")
                throw GooglePlacesError.apiError(searchResponse.status)
            }

            print("✅ GooglePlaces: Found \(searchResponse.results.count) places")
            return searchResponse.results

        } catch let decodingError as DecodingError {
            print("❌ GooglePlaces: JSON Decoding Error: \(decodingError)")
            throw GooglePlacesError.apiError("DECODING_ERROR")
        } catch {
            print("❌ GooglePlaces: Network Error: \(error.localizedDescription)")
            throw GooglePlacesError.networkError
        }
    }

    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        print("📍 GooglePlaces: Getting place details for ID: \(placeId)")

        var urlComponents = URLComponents(string: "\(baseURL)/details/json")!

        urlComponents.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "fields", value: "place_id,name,formatted_address,rating,photos,types,geometry"),
        ]

        guard let url = urlComponents.url else {
            print("❌ GooglePlaces: Failed to create URL for place details")
            throw GooglePlacesError.invalidURL
        }

        print("GooglePlaces: Requesting place details from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ GooglePlaces: Invalid HTTP response for place details")
                throw GooglePlacesError.networkError
            }

            print("GooglePlaces: Place details HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                print("❌ GooglePlaces: Place details HTTP Error - Status: \(httpResponse.statusCode)")
                throw GooglePlacesError.networkError
            }

            let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            print("GooglePlaces: Place details API Status: \(detailsResponse.status)")

            guard detailsResponse.status == "OK" else {
                print("❌ GooglePlaces: Place details API Error - Status: \(detailsResponse.status)")
                throw GooglePlacesError.apiError(detailsResponse.status)
            }

            print("✅ GooglePlaces: Successfully retrieved place details for: \(detailsResponse.result.name)")
            return detailsResponse.result

        } catch let decodingError as DecodingError {
            print("❌ GooglePlaces: Place details JSON Decoding Error: \(decodingError)")
            throw GooglePlacesError.apiError("DECODING_ERROR")
        } catch {
            print("❌ GooglePlaces: Place details Network Error: \(error.localizedDescription)")
            throw GooglePlacesError.networkError
        }
    }

    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> String {
        print("📷 GooglePlaces: Generating photo URL for reference")

        var urlComponents = URLComponents(string: "\(baseURL)/photo")!

        urlComponents.queryItems = [
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "key", value: apiKey),
        ]

        let photoURL = urlComponents.url?.absoluteString ?? ""

        if photoURL.isEmpty {
            print("❌ GooglePlaces: Failed to generate photo URL")
        } else {
            print("✅ GooglePlaces: Generated photo URL:")
        }

        return photoURL
    }

    func getFirstPhotoURL(from place: PlaceResult, maxWidth: Int = 400) -> String? {
        print("📷 GooglePlaces: Getting first photo URL for place: \(place.name)")

        guard let photos = place.photos,
              let firstPhoto = photos.first
        else {
            print("❌ GooglePlaces: No photos available for place: \(place.name)")
            return nil
        }

        print("✅ GooglePlaces: Found \(photos.count) photo(s) for place: \(place.name)")
        return getPhotoURL(photoReference: firstPhoto.photoReference, maxWidth: maxWidth)
    }

    func getFirstPhotoURL(from placeDetails: PlaceDetails, maxWidth: Int = 400) -> String? {
        print("📷 GooglePlaces: Getting first photo URL for place details: \(placeDetails.name)")

        guard let photos = placeDetails.photos,
              let firstPhoto = photos.first
        else {
            print("❌ GooglePlaces: No photos available for place details: \(placeDetails.name)")
            return nil
        }

        print("✅ GooglePlaces: Found \(photos.count) photo(s) for place details: \(placeDetails.name)")
        return getPhotoURL(photoReference: firstPhoto.photoReference, maxWidth: maxWidth)
    }

    // MARK: - Helper Methods

    func getCategoryFromTypes(_ types: [String]) -> CategoryType {
        print("GooglePlaces: Categorizing place with types: \(types)")

        // Map Google Places types to our CategoryType enum
        let typeSet = Set(types.map { $0.lowercased() })

        let category: CategoryType
        if typeSet.contains("restaurant") || typeSet.contains("food") || typeSet.contains("meal_takeaway") || typeSet.contains("cafe") {
            category = .restaurants
        } else if typeSet.contains("lodging") || typeSet.contains("hotel") {
            category = .hostels
        } else if typeSet.contains("night_club") || typeSet.contains("bar") {
            category = .nightlife
        } else if typeSet.contains("tourist_attraction") || typeSet.contains("museum") || typeSet.contains("park") {
            category = .sights
        } else if typeSet.contains("amusement_park") || typeSet.contains("zoo") || typeSet.contains("aquarium") {
            category = .activities
        } else {
            category = .other
        }

        print("GooglePlaces: Categorized as: \(category.rawValue)")
        return category
    }
}

// MARK: - Error Handling

enum GooglePlacesError: Error, LocalizedError {
    case invalidURL
    case networkError
    case apiError(String)
    case noResults
    case invalidAPIKey
    case invalidCoordinates

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Google Places API request"
        case .networkError:
            return "Network error occurred while fetching place data"
        case let .apiError(status):
            return "Google Places API error: \(status)"
        case .noResults:
            return "No places found for the search query"
        case .invalidAPIKey:
            return "Invalid Google Places API key"
        case .invalidCoordinates:
            return "Invalid coordinates provided for location-based search"
        }
    }
}
