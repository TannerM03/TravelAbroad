//
//  TravelAbroadApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import Foundation
import SwiftUI

@main
struct TravelAbroadApp: App {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
//    @State private var isAuthenticated = false

    init() {
        // App initialization
    }

    var body: some Scene {
        WindowGroup {
            // Shows main app interface if authenticated, otherwise show login screen
            if isAuthenticated {
                TabBarView(isAuthenticated: $isAuthenticated)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}

