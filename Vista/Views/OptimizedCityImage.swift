//
//  OptimizedCityImage.swift
//  TravelAbroad
//
//  Created by Claude on 3/11/26.
//

import SwiftUI
import Kingfisher

struct OptimizedCityImage: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            KFImage(url)
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: width * 3, height: height * 3)))
                .scaleFactor(UIScreen.main.scale)
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
        }
    }
}
