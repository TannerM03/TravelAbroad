//
//  ProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Foundation
import Observation
import PhotosUI
import Supabase
import SwiftUI

@MainActor
@Observable
class ProfileViewModel {
    var username: String = ""
    var user: User?
    var profileImageURL: String?
    var userId: UUID?
    var imageState: ImageState = .empty
    var citiesVisited: Int = 0
    var spotsReviewed: Int = 0
    var countriesVisited: Int = 0
    var imageSelection: PhotosPickerItem? {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }

    private var imageCache: [String: Image] = [:]

    func logOut() async throws {
        try await SupabaseManager.shared.supabase.auth.signOut()
    }

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id

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
//                countriesVisited = try await SupabaseManager.shared.fetchNumCountriesVisited(userId: userId)
//                citiesVisited = try await SupabaseManager.shared.fetchNumCitiesVisited(userId: userId)
//                recsSubmitted = try await SupabaseManager.shared.fetchNumRecsSubmitted(userId: userId)

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

    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case let .success(profileImage?):
                    self.imageState = .success(profileImage.image)
                    Task {
                        await SupabaseManager.shared.uploadProfileImageToSupabase(image: profileImage.uiImage)
                    }
                case .success(nil):
                    self.imageState = .empty
                case let .failure(error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    func refreshTravelStats() async {
        guard let userId = userId else { return }
        do {
            let travelStats = try await SupabaseManager.shared.fetchTravelStats(userId: userId)
            countriesVisited = travelStats.countriesVisited
            citiesVisited = travelStats.citiesVisited
            spotsReviewed = travelStats.spotsVisited
        } catch {
            print("Failed to refresh travel stats: \(error)")
        }
    }
}
