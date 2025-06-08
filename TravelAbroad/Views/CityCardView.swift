//
//  CityCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/6/25.
//

import SwiftUI

struct CityCardView: View {
    let cityName: String
    let imageName: String
    let rating: Double?
    let flagEmoji: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipped()
                    .cornerRadius(12)
                
                if let flag = flagEmoji {
                    Text(flag)
                        .font(.title)
                        .padding(6)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            HStack {
                Text(cityName)
                Spacer()
                if let rating = rating {
                    Text("\(String(format: "%.1f", rating))")
                }
            }
                .font(.title2)
                .foregroundColor(.primary)
        }
        .frame(width: 150)
        .shadow(radius: 5)
    }
}


#Preview {
    CityCardView(cityName: "Madrid", imageName: "madrid", rating: 9.2, flagEmoji: "🇪🇸")
}
