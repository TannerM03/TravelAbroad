//
//  Supabase.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/1/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://tyttgzrqntyzehfufeqx.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5dHRnenJxbnR5emVoZnVmZXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MjIzNDEsImV4cCI6MjA2Mjk5ODM0MX0.B_kWPnoSjiENKIfggFqMWzdu_vdnKML1gJmzVy4NCcs"
    )
    
    
    func fetchCities() async throws -> [City] {
        print("service")
        let cities: [City] = try await supabase.from("cities")
            .select()
            .execute()
            .value
        return cities
    }
}
