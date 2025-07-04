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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlStr = rec.imageUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 170)
                    .clipped()
                    .cornerRadius(15)
            } else {
                KFImage(URL(string: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 170)
                    .clipped()
                    .cornerRadius(15)
            }
            HStack(alignment: .center, spacing: 8) {
                Text(rec.name)
                    .font(.headline)
                Spacer()
                Text(rec.category.rawValue.capitalized)
                    .font(.subheadline)
                    .padding(6)
                    .background(rec.category.pillColor)
                    .cornerRadius(8)
            }
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                Text("Avg Rating: \(String(format: "%.1f", rec.avgRating))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let desc = rec.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color(Color.secondary).opacity(0.07), radius: 5, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

#Preview {
    RecommendationsCardView(rec: Recommendation(
        id: "1",
        userId: "example_user",
        cityId: "city_1",
        category: .restaurants,
        name: "Test Restaurant",
        description: "A great local spot for amazing food.",
        imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
        location: "123 Main St",
        avgRating: 5
    ))
}
