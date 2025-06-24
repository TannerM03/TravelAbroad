//
//  GooglePlacesAPI.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/3/25.
//

import Foundation
import GooglePlacesSwift
import UIKit

@MainActor
class GooglePlacesManager {
    static let shared = GooglePlacesManager()

    private let placesClient = PlacesClient.shared

    private init() {} // Singleton pattern

    // Fetch place image for a given placeID
    func fetchPlaceImage(placeID: String) async throws -> UIImage? {
        let fetchPlaceRequest = FetchPlaceRequest(
            placeID: placeID,
            placeProperties: [.displayName, .photos]
        )

        let fetchPlaceResult = await placesClient.fetchPlace(with: fetchPlaceRequest)

        switch fetchPlaceResult {
        case let .success(place):
            guard let photo = place.photos?.first else {
                print("No photo found for this place.")
                return nil
            }

            let fetchPhotoRequest = FetchPhotoRequest(photo: photo, maxSize: CGSize(width: 800, height: 800))
            let fetchPhotoResult = await placesClient.fetchPhoto(with: fetchPhotoRequest)

            switch fetchPhotoResult {
            case let .success(uiImage):
                return uiImage
            case let .failure(photoError):
                print("Error fetching photo: \(photoError)")
                return nil
            }

        case let .failure(placeError):
            print("Error fetching place: \(placeError)")
            return nil
        }
    }
}
