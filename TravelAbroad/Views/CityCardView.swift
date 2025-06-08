//
//  CityCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/6/25.
//

import SwiftUI

struct CityCardView: View {
    let cityName: String
    let imageUrl: String?
    let rating: Double?
    let flagEmoji: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                
                //logic to get the image or just return madrid, the madrid part isn't working but idrc because i'm gonna figure out the google images thing at some point
                if let url = imageUrl, let url = URL(string: url) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 160, height: 160)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            Image("madrid")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipped()
                                .cornerRadius(12)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                if let flag = flagEmoji {
                    Text(flag)
                        .font(.title)
                        .padding(6)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            
            //city name and rating
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
    CityCardView(cityName: "Madrid", imageUrl: "madrid", rating: 9.2, flagEmoji: "🇪🇸")
}
