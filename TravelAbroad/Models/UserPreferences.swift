//
//  UserPreferences.swift
//  TravelAbroad
//
//  Created for ML-driven itinerary generation
//

import Foundation

// MARK: - Core Preference Models

struct UserPreferences: Codable {
    let id: UUID
    let userId: UUID
    var travelStyle: TravelStylePreferences
    var activityPreferences: ActivityPreferences
    var practicalPreferences: PracticalPreferences
    var additionalPreferences: AdditionalPreferences
    let createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.travelStyle = TravelStylePreferences()
        self.activityPreferences = ActivityPreferences()
        self.practicalPreferences = PracticalPreferences()
        self.additionalPreferences = AdditionalPreferences()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Travel Style & Pace

struct TravelStylePreferences: Codable {
    var energyLevel: EnergyLevel = .balanced
    var socialPreference: SocialPreference = .flexible
    var timePreference: TimePreference = .flexible
    var budgetRange: BudgetRange = .moderate
    
    enum EnergyLevel: String, CaseIterable, Codable {
        case relaxed = "relaxed"
        case balanced = "balanced" 
        case packed = "packed"
        
        var displayName: String {
            switch self {
            case .relaxed: return "Relaxed Explorer"
            case .balanced: return "Balanced Traveler"
            case .packed: return "Adventure Seeker"
            }
        }
        
        var description: String {
            switch self {
            case .relaxed: return "2-3 activities per day, plenty of downtime"
            case .balanced: return "4-5 activities per day, some flexibility"
            case .packed: return "6+ activities per day, maximize everything"
            }
        }
    }
    
    enum SocialPreference: String, CaseIterable, Codable {
        case solo = "solo"
        case smallGroup = "small_group"
        case largeGroup = "large_group"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .solo: return "Solo Explorer"
            case .smallGroup: return "Small Groups (2-4)"
            case .largeGroup: return "Large Groups (5+)"
            case .flexible: return "Any Size Works"
            }
        }
    }
    
    enum TimePreference: String, CaseIterable, Codable {
        case earlyBird = "early_bird"
        case nightOwl = "night_owl"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .earlyBird: return "Early Bird (6AM-8PM)"
            case .nightOwl: return "Night Owl (10AM-12AM)"
            case .flexible: return "I'm Flexible"
            }
        }
    }
    
    enum BudgetRange: String, CaseIterable, Codable {
        case budget = "budget"
        case moderate = "moderate"
        case comfortable = "comfortable"
        case luxury = "luxury"
        
        var displayName: String {
            switch self {
            case .budget: return "Student Budget ($0-30/day)"
            case .moderate: return "Moderate ($30-70/day)"
            case .comfortable: return "Comfortable ($70-150/day)"
            case .luxury: return "Luxury ($150+/day)"
            }
        }
    }
}

// MARK: - Activity Preferences

struct ActivityPreferences: Codable {
    var preferences: [ActivityType: PreferenceLevel] = [:]
    
    // Initialize with all activity types set to neutral
    init() {
        for activityType in ActivityType.allCases {
            preferences[activityType] = .likeIt
        }
    }
    
    enum ActivityType: String, CaseIterable, Codable {
        case cultural = "cultural"
        case foodDining = "food_dining"
        case nightlife = "nightlife"
        case outdoor = "outdoor"
        case shopping = "shopping"
        case photography = "photography"
        case localEvents = "local_events"
        
        var displayName: String {
            switch self {
            case .cultural: return "Museums & Historical Sites"
            case .foodDining: return "Food & Dining Experiences"
            case .nightlife: return "Nightlife & Bars"
            case .outdoor: return "Outdoor Activities"
            case .shopping: return "Shopping & Markets"
            case .photography: return "Photography & Instagram Spots"
            case .localEvents: return "Local Events & Festivals"
            }
        }
        
        var icon: String {
            switch self {
            case .cultural: return "building.columns"
            case .foodDining: return "fork.knife"
            case .nightlife: return "wineglass"
            case .outdoor: return "leaf"
            case .shopping: return "bag"
            case .photography: return "camera"
            case .localEvents: return "party.popper"
            }
        }
    }
    
    enum PreferenceLevel: String, CaseIterable, Codable {
        case loveIt = "love_it"
        case likeIt = "like_it"
        case notMyFav = "not_my_fav"
        
        var displayName: String {
            switch self {
            case .loveIt: return "Love it!"
            case .likeIt: return "Like it"
            case .notMyFav: return "Not my fav"
            }
        }
        
        var color: String {
            switch self {
            case .loveIt: return "green"
            case .likeIt: return "blue"
            case .notMyFav: return "gray"
            }
        }
        
        var weight: Double {
            switch self {
            case .loveIt: return 1.0
            case .likeIt: return 0.6
            case .notMyFav: return 0.2
            }
        }
    }
}

// MARK: - Practical Preferences

struct PracticalPreferences: Codable {
    var maxWalkingDistance: WalkingDistance = .moderate
    var transportationPreference: TransportationPreference = .flexible
    var accommodationStyle: AccommodationStyle = .flexible
    
    enum WalkingDistance: String, CaseIterable, Codable {
        case short = "short"          // 0-1 miles
        case moderate = "moderate"    // 1-2 miles
        case long = "long"           // 2+ miles
        
        var displayName: String {
            switch self {
            case .short: return "Short (0-1 miles)"
            case .moderate: return "Moderate (1-2 miles)"
            case .long: return "Long (2+ miles)"
            }
        }
        
        var maxDistanceInMiles: Double {
            switch self {
            case .short: return 1.0
            case .moderate: return 2.0
            case .long: return 3.0
            }
        }
    }
    
    enum TransportationPreference: String, CaseIterable, Codable {
        case walking = "walking"
        case publicTransport = "public_transport"
        case rideshare = "rideshare"
        case rental = "rental"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .walking: return "Prefer Walking"
            case .publicTransport: return "Public Transportation"
            case .rideshare: return "Rideshare/Taxi"
            case .rental: return "Rental Car/Bike"
            case .flexible: return "Whatever Works"
            }
        }
    }
    
    enum AccommodationStyle: String, CaseIterable, Codable {
        case hostel = "hostel"
        case hotel = "hotel"
        case airbnb = "airbnb"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .hostel: return "Hostels (Social)"
            case .hotel: return "Hotels (Private)"
            case .airbnb: return "Airbnb/Local"
            case .flexible: return "I'm Flexible"
            }
        }
    }
}

// MARK: - Additional ML-Relevant Preferences

struct AdditionalPreferences: Codable {
    var planningStyle: PlanningStyle = .structured
    var riskTolerance: RiskTolerance = .moderate
    var culturalImmersion: CulturalImmersion = .moderate
    var crowdTolerance: CrowdTolerance = .moderate
    
    enum PlanningStyle: String, CaseIterable, Codable {
        case loose = "loose"
        case structured = "structured"
        case detailed = "detailed"
        
        var displayName: String {
            switch self {
            case .loose: return "Loose Structure"
            case .structured: return "Mixture"
            case .detailed: return "Every Detail Planned"
            }
        }
    }
    
    enum RiskTolerance: String, CaseIterable, Codable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Safe & Familiar"
            case .moderate: return "Calculated Risks"
            case .high: return "Adventure Seeker"
            }
        }
    }
    
    enum CulturalImmersion: String, CaseIterable, Codable {
        case minimal = "minimal"
        case moderate = "moderate"
        case deep = "deep"
        
        var displayName: String {
            switch self {
            case .minimal: return "Tourist Highlights"
            case .moderate: return "Mix of Both"
            case .deep: return "Local Experiences"
            }
        }
    }
    
    enum CrowdTolerance: String, CaseIterable, Codable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Prefer Quiet Spots"
            case .moderate: return "Some Crowds OK"
            case .high: return "Love Bustling Places"
            }
        }
    }
}

// MARK: - Onboarding State Management

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case travelStyle = 1
    case activityPreferences = 2
    case walkingDistance = 3
    case additionalPreferences = 4
    case summary = 5
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to TravelAbroad!"
        case .travelStyle: return "Your Travel Style"
        case .activityPreferences: return "Activity Preferences"
        case .walkingDistance: return "Getting Around"
        case .additionalPreferences: return "Final Touches"
        case .summary: return "All Set!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Let's personalize your travel experience"
        case .travelStyle: return "How do you like to travel?"
        case .activityPreferences: return "Drag activities to show your preferences"
        case .walkingDistance: return "How far are you comfortable walking?"
        case .additionalPreferences: return "A few more details to perfect your itineraries"
        case .summary: return "Your preferences are saved. Let's explore!"
        }
    }
    
    var progress: Double {
        return Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
