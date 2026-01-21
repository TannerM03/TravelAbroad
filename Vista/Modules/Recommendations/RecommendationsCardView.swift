//
// RecommendationsCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/17/25.
//

import Kingfisher
import SwiftUI

struct RecommendationsCardView: View {
    let rec: Recommendation

    private var categoryIcon: String {
        switch rec.category {
        case .all: return "mappin.and.ellipse.circle"
        case .activities: return "figure.hiking"
        case .barsClubs: return "music.note"
        case .restaurants: return "fork.knife"
        case .hostels: return "bed.double"
        case .sights: return "camera"
        case .other: return "location"
        }
    }

    var body: some View {
        NavigationLink(destination: CommentsView(recommendation: rec)) {
            VStack(alignment: .leading, spacing: 0) {
                if let urlStr = rec.imageUrl, let url = URL(string: urlStr) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 170)
                        .clipped()
                        .cornerRadius(15)
                } else {
                    ZStack {
                        rec.category.pillColor.opacity(0.3)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 40))
                            .foregroundColor(rec.category.pillColor)
                    }
                    .frame(height: 170)
                    .cornerRadius(15)
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(rec.name)
                        .foregroundColor(.primary)
                        .font(.headline)
                        .padding(.top, 5)
                    Spacer()
                    Text(rec.category.rawValue.capitalized)
                        .foregroundColor(.primary)
                        .font(.subheadline)
                        .padding(6)
                        .background(rec.category.pillColor)
                        .cornerRadius(12)
                }
                .padding(.vertical, 8)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.footnote)
                    Text("\(String(format: "%.1f", rec.avgRating)) Rating")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: Color(Color.secondary).opacity(0.07), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .overlay(alignment: .leading) {
            // Block taps in the left 100px to allow swipe-back gesture
            Color.clear
                .frame(width: 60)
                .contentShape(Rectangle())
                .allowsHitTesting(true)
        }
    }
}

// #Preview {
//    RecommendationsCardView(rec: Recommendation(
//        id: "1",
//        userId: "example_user",
//        cityId: "city_1",
//        category: .restaurants,
//        name: "Test Restaurant",
//        description: "A great local spot for amazing food.",
//        imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
//        location: "123 Main St",
//        avgRating: 5
//    ))
// }
