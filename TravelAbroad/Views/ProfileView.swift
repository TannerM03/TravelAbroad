//
//  ProfileView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Supabase
import SwiftUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    // Need to make vm for getting real user data
    @StateObject var vm = ProfileViewModel()
    @State private var profileImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil

    @State private var wishlistCities = ["Paris", "Tokyo", "Madrid"]
    @State private var user: User? = nil

    var email: String {
        user?.email ?? ""
    }

    var username: String {
        user?.userMetadata["username"] as? String ?? ""
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack(alignment: .center) {
                        VStack(alignment: .center, spacing: 8) {
                            if let image = profileImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 150, height: 150)
                                    .overlay(Image(systemName: "person.fill").font(.largeTitle))
                            }
//                            Text(user?.userMetadata["username"] as? String ?? "")
                            Text(email)
                        }
                    }
                }

                Section(header: Text("Dream Trips")) {
                    if wishlistCities.isEmpty {
                        Text("No cities added yet.")
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(wishlistCities, id: \.self) { city in
                            Text(city)
                        }
                    }
                }
                Section {
                    Button {
                        Task {
                            try await vm.logOut()
                            isAuthenticated = false
                        }
                    } label: {
                        Text("Log out")
                    }
                }
            }
            .navigationTitle(username)
        }.task {
            user = try? await SupabaseManager.shared.supabase.auth.session.user
        }
    }
}

// #Preview {
//    ProfileView()
// }
