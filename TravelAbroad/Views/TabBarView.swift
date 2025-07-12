//
//  TabBarView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import SwiftUI

struct TabBarView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var cityListViewModel = CityListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some View {
        TabView {
            CitiesView(vm: cityListViewModel)
                .tabItem {
                    Label("Cities", systemImage: "building.2.crop.circle")
                }
            ProfileView(isAuthenticated: $isAuthenticated, vm: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .task {
            // Preload profile data on app launch
            if profileViewModel.user == nil {
                await profileViewModel.fetchUser()
            }
        }
    }
}

#Preview {
    TabBarView(isAuthenticated: .constant(true))
}
