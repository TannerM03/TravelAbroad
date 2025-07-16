//
//  ProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Foundation
import PhotosUI
import Supabase
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var user: User?
    @Published var profileImageURL: String?
    @Published var userId: UUID? = nil
    @Published var imageState: ImageState = .empty
    @Published var citiesVisited: Int = 0
    @Published var recsSubmitted: Int = 0
    @Published var imageSelection: PhotosPickerItem? = nil {
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
                citiesVisited = try await SupabaseManager.shared.fetchNumCitiesVisited(userId: userId)
                recsSubmitted = try await SupabaseManager.shared.fetchNumRecsSubmitted(userId: userId)

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
}
