//
//  OptimizedProfileImage.swift
//  TravelAbroad
//
//  Created by Claude on 3/11/26.
//

import SwiftUI
import Kingfisher

struct OptimizedProfileImage: View {
    let imageURL: String?
    let isPopular: Bool
    let size: CGFloat = 125

    var body: some View {
        Group {
            if let urlString = imageURL, let url = urlString.cdnURL {
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 3, height: size * 3)))
                    .scaleFactor(UIScreen.main.scale)
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(borderOverlay)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: size * 0.4))
                    )
                    .frame(width: size, height: size)
                    .overlay(borderOverlay)
            }
        }
        .shadow(radius: 4)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if isPopular {
            Circle().stroke(Color.white, lineWidth: 1)
            Circle().stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .padding(3)
            Circle().stroke(Color.white, lineWidth: 1)
                .padding(6)
        } else {
            Circle().stroke(Color.white, lineWidth: 6)
        }
    }
}
