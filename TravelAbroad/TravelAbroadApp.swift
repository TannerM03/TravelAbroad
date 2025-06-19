//
//  TravelAbroadApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import SwiftUI
import GooglePlacesSwift

@main
struct TravelAbroadApp: App {
    
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
            TabBarView()
        }
    }
}



//Google places API should be good for getting images of the places the user wants to add a rec for
