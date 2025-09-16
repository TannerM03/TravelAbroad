//
//  TabBarView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import SwiftUI

struct TabBarView: View {
    @Binding var isAuthenticated: Bool
    @State private var cityListViewModel = CityListViewModel()
    @State private var profileViewModel = ProfileViewModel()
    @State private var selectedTab = 0
    @State private var selectedUserId: String?

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // If user taps Social tab while already on Social tab with a user selected, reset to default
                if selectedTab == 1 && newValue == 1 && selectedUserId != nil {
                    selectedUserId = nil
                } else {
                    selectedTab = newValue
                }
            }
        )
    }
    
    var body: some View {
        TabView(selection: tabSelection) {
            CitiesView(vm: cityListViewModel)
                .tabItem {
                    Label("Cities", systemImage: "building.2.crop.circle")
                }
                .tag(0)
            Group {
                if let userId = selectedUserId {
                    OtherProfileView(selectedUserId: userId)
                        .id(userId)
                } else {
                    Text("Friends Coming Soon!")
                }
            }
            .tabItem {
                Label("Social", systemImage: "magnifyingglass.circle.fill")
            }
            .tag(1)
            Text("Itinerary Builder Coming Soon!")
                .tabItem {
                    Label("Itinerary", systemImage: "airplane.circle.fill")
                }
                .tag(2)
            ProfileView(isAuthenticated: $isAuthenticated, vm: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToSocialTab"))) { notification in
            selectedTab = 1 // Social tab
            // Set the userId to show SocialView instead of "Friends Coming Soon!"
            if let userId = notification.object as? String {
                selectedUserId = userId
                print("Switching to social tab for user: \(userId)")
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
