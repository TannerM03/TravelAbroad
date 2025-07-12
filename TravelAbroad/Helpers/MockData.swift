//
//  MockData.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/26/25.
//

import Foundation

class MockData {
    static let shared = MockData()

    // MARK: - Mock Cities

    static let sampleCities: [City] = [
        City(
            id: "49e5f9fb-e080-4365-9de6-cab823acf033",
            name: "Madrid",
            country: "Spain",
            imageUrl: "https://images.unsplash.com/photo-1539037116277-4db20889f2d4",
            avgRating: 4.5
        ),
        City(
            id: "8c9a7b2d-e4f3-4a5b-9c8d-7e6f5a4b3c2d",
            name: "Paris",
            country: "France",
            imageUrl: "https://images.unsplash.com/photo-1502602898536-47ad22581b52",
            avgRating: 4.7
        ),
        City(
            id: "3f2e1d9c-8b7a-6958-4736-251e0d9c8b7a",
            name: "Tokyo",
            country: "Japan",
            imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf",
            avgRating: 4.8
        ),
        City(
            id: "7a6b5c4d-3e2f-1a9b-8c7d-6e5f4a3b2c1d",
            name: "New York",
            country: "United States",
            imageUrl: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9",
            avgRating: 4.2
        ),
        City(
            id: "9b8c7d6e-5f4a-3b2c-1d9e-8f7a6b5c4d3e",
            name: "Barcelona",
            country: "Spain",
            imageUrl: "https://images.unsplash.com/photo-1558642452-9d2a7deb7f62",
            avgRating: 4.6
        ),
    ]

    // MARK: - Mock Recommendations

    static let sampleRecommendations: [Recommendation] = [
        Recommendation(
            id: "rec1",
            userId: "user1",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .restaurants,
            name: "Sobrino de Botín",
            description: "The world's oldest restaurant serving traditional Castilian cuisine since 1725.",
            imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
            location: "Calle Cuchilleros, 17, Madrid",
            avgRating: 4.2
        ),
        Recommendation(
            id: "rec2",
            userId: "user2",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .sights,
            name: "Prado Museum",
            description: "World-famous art museum featuring works by Velázquez, Goya, and other Spanish masters.",
            imageUrl: "https://images.unsplash.com/photo-1541961017774-22349e4a1262",
            location: "Calle de Ruiz de Alarcón, 23, Madrid",
            avgRating: 4.8
        ),
        Recommendation(
            id: "rec3",
            userId: "user3",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .nightlife,
            name: "Kapital",
            description: "7-floor nightclub with different music styles on each level. Madrid's most famous club.",
            imageUrl: "https://images.unsplash.com/photo-1566737236500-c8ac43014a8e",
            location: "Calle de Atocha, 125, Madrid",
            avgRating: 4.1
        ),
        Recommendation(
            id: "rec4",
            userId: "user4",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .hostels,
            name: "The Hat Madrid",
            description: "Stylish hostel in the heart of Madrid with rooftop terrace and modern amenities.",
            imageUrl: "https://images.unsplash.com/photo-1555854877-bab0e564b8d5",
            location: "Calle Imperial, 9, Madrid",
            avgRating: 4.3
        ),
        Recommendation(
            id: "rec5",
            userId: "user5",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .activities,
            name: "Retiro Park",
            description: "Beautiful historic park perfect for walks, boat rides, and people watching.",
            imageUrl: "https://images.unsplash.com/photo-1578662996442-48f60103fc96",
            location: "Plaza de la Independencia, 7, Madrid",
            avgRating: 4.7
        ),
        Recommendation(
            id: "rec6",
            userId: "user6",
            cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
            category: .other,
            name: "Mercado de San Miguel",
            description: "Historic covered market with gourmet food stalls and local delicacies.",
            imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            location: "Plaza de San Miguel, s/n, Madrid",
            avgRating: 4.0
        ),
    ]

    // MARK: - Helper Methods

    static func getRecommendations(for cityId: String) -> [Recommendation] {
        return sampleRecommendations.filter { $0.cityId == cityId }
    }

    static func getRecommendations(for category: CategoryType, cityId: String) -> [Recommendation] {
        return sampleRecommendations.filter {
            $0.category == category && $0.cityId == cityId
        }
    }
}

// MARK: - Preview Environment Configuration

extension MockData {
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
