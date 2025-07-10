//
//  ConfigManager.swift
//  TravelAbroad
//
//  Created for secure API key management
//

import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private var config: [String: Any] = [:]
    
    private init() {
        loadConfig()
    }
    
    private func loadConfig() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found or invalid format")
        }
        self.config = configData
    }
    
    func getValue(for key: String) -> String {
        guard let value = config[key] as? String else {
            fatalError("Key '\(key)' not found in Config.plist")
        }
        return value
    }
    
    var supabaseURL: String {
        return getValue(for: "SupabaseURL")
    }
    
    var supabaseKey: String {
        return getValue(for: "SupabaseKey")
    }
    
    var googlePlacesAPIKey: String {
        return getValue(for: "GooglePlacesAPIKey")
    }
}