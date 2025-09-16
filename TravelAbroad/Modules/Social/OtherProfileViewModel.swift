//
//  OtherProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/15/25.
//

import Foundation
import PhotosUI
import Supabase
import SwiftUI
import Observation

@MainActor
@Observable
class OtherProfileViewModel {
    var username: String = ""
    var user: User?
    var profileImageURL: String?
    var userId: UUID?
    var imageState: ImageState = .empty
    var citiesVisited: Int = 0
    var spotsReviewed: Int = 0
    var countriesVisited: Int = 0

    private var imageCache: [String: Image] = [:]
    
    init(userId: String) {
        self.userId = UUID(uuidString: userId) ?? nil
    }

    func fetchUser() async {
        do {
            if let userId = userId {
                username = try await SupabaseManager.shared.fetchUsername(userId: userId)
                profileImageURL = try await SupabaseManager.shared.fetchProfilePic(userId: userId)

                if let urlString = profileImageURL, let url = URL(string: urlString) {
                    await loadImageFromURL(url)
                }

                let travelStats = try await SupabaseManager.shared.fetchTravelStats(userId: userId)
                countriesVisited = travelStats.countriesVisited
                citiesVisited = travelStats.citiesVisited
                spotsReviewed = travelStats.spotsVisited
                print("fetched other user travel stats: countriesvisited: \(countriesVisited)")

            } else {
                print("userId didn't work yet")
            }

        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    private func loadImageFromURL(_ url: URL) async {
        let urlString = url.absoluteString

        // Check cache first
        if let cachedImage = imageCache[urlString] {
            imageState = .success(cachedImage)
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                imageCache[urlString] = image
                imageState = .success(image)
            }
        } catch {
            print("Failed to load image from URL: \(error)")
        }
    }
}
