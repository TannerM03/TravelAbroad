//
//  ProfileCityCard.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/3/25.
//

import Kingfisher
import SwiftUI

struct ProfileCityCard: View {
    let cityName: String
    let imageUrl: String?
    let rating: Double?
    let flagEmoji: String?

    var body: some View {
        ZStack {
            if let url = imageUrl, let url = URL(string: url) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipped()
            }

            // Subtle gradient for text readability
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    if let flag = flagEmoji {
                        Text(flag)
                            .font(.title3)
                            .padding(6)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                    if let rating = rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption2.weight(.bold))
                            Text(String(format: "%.1f", rating))
                                .font(.caption.weight(.bold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(8)

                Spacer()

                HStack {
                    Text(cityName)
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// #Preview {
//    TravelHistoryCityCardView()
// }
