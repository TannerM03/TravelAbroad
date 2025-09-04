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
            Text("Friends Coming Soon!")
                .tabItem {
                    Label("Social", systemImage: "magnifyingglass.circle.fill")
                }
            CitiesView(vm: cityListViewModel)
                .tabItem {
                    Label("Cities", systemImage: "building.2.crop.circle")
                }
            Text("Itinerary Builder Coming Soon!")
                .tabItem {
                    Label("Itinerary", systemImage: "airplane.circle.fill")
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
