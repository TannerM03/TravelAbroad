//
//  TabBarView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import SwiftUI

struct TabBarView: View {
    @Binding var isAuthenticated: Bool
    var body: some View {
        TabView {
            CitiesView()
                .tabItem {
                    Label("Cities", systemImage: "building.2.crop.circle")
                }
            ProfileView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    TabBarView(isAuthenticated: .constant(true))
}
