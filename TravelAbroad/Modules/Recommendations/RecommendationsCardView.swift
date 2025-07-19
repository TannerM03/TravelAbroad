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
    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: CommentsView(recommendation: rec)) {
            VStack(spacing: 0) {
                ZStack {
                    if let urlStr = rec.imageUrl, let url = URL(string: urlStr) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6), Color.teal.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text(categoryEmoji(for: rec.category))
                                    .font(.system(size: 20))
                                Text(rec.category.rawValue.capitalized)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(12)
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(rec.name)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .multilineTextAlignment(.leading)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12, weight: .bold))
                                    Text(String(format: "%.1f rating", rec.avgRating))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    isPressed = false
                }
            }
        }
    }
    
    private func categoryEmoji(for category: CategoryType) -> String {
        switch category {
        case .restaurants: return "🍽️"
        case .hostels: return "🏨"
        case .activities: return "🎯"
        case .nightlife: return "🌃"
        case .sights: return "🏛️"
        case .other: return "📍"
        }
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
