//
//  TravelAbroadApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import Foundation
import SwiftUI
import GooglePlacesSwift

@main
struct TravelAbroadApp: App {
    
//    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isAuthenticated = false
    
    init() {
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let apiKey = dict["GooglePlacesAPIKey"] as? String {
                PlacesClient.provideAPIKey(apiKey)
            } else {
                print("⚠️ Failed to load Google Places API Key")
            }
        }
    
    var body: some Scene {
        WindowGroup {
            // Shows main app interface if authenticated, otherwise show login screen
            if isAuthenticated {
                TabBarView()
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}



//Google places API should be good for getting images of the places the user wants to add a rec for

