//
//  CityCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/6/25.
//

import Kingfisher
import SwiftUI

struct CityCardView: View {
    let cityName: String
    let imageUrl: String?
    let rating: Double?
    let flagEmoji: String?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let url = imageUrl, let url = URL(string: url) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                }
                
                // Gradient overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack {
                    HStack {
                        if let flag = flagEmoji {
                            Text(flag)
                                .font(.system(size: 24))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                        if let rating = rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12, weight: .bold))
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cityName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            Text("Tap to explore →")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
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
    }
}

#Preview {
    VStack(spacing: 20) {
        CityCardView(cityName: "Madrid", imageUrl: "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//madrid.jpg", rating: 9.2, flagEmoji: "🇪🇸")
        CityCardView(cityName: "Paris", imageUrl: nil, rating: 8.5, flagEmoji: "🇫🇷")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}