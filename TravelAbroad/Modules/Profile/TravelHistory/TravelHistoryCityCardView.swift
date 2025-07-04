//
//  TravelHistoryCityCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/3/25.
//

import SwiftUI
import Kingfisher

struct TravelHistoryCityCardView: View {
        let cityName: String
        let imageUrl: String?
        let rating: Double?
        let flagEmoji: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let url = imageUrl, let url = URL(string: url) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipped()
                            .cornerRadius(12)
                    }

                }.overlay {
                    VStack(alignment: .leading) {
                        HStack {
                            if let flag = flagEmoji {
                                Text(flag)
                                    .font(.title)
                                    .padding(2)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(Circle())
                                    .padding(3)
                            }
                            Spacer()
                            if let rating = rating {
                                Text("\(String(format: "%.1f", rating))")
                                    .font(.title2)
                            }
                        }
                        Spacer()
                        HStack {
                            Text(cityName)
                        }
                        .font(.title2)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 150)
                    .shadow(radius: 5)
                }
            }
        }
    }

//#Preview {
//    TravelHistoryCityCardView()
//}
