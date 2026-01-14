//
//  FeedImageCarousel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 12/13/25
//

import Kingfisher
import SwiftUI

struct FeedImageCarousel: View {
    let commentImageUrl: String? // User-uploaded image
    let spotImageUrl: String? // Official spot image
    let categoryIcon: String
    let categoryColor: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        // Case 1: No images
        if commentImageUrl == nil && spotImageUrl == nil {
            placeholderView
        }
        // Case 2: Only spot image
        else if commentImageUrl == nil, let officialUrl = spotImageUrl {
            singleImageView(url: officialUrl, badgeText: "Official Spot Photo")
        }
        // Case 3: User image and official image but are different, show both
        else if let userUrl = commentImageUrl, let officialUrl = spotImageUrl, userUrl != officialUrl {
            carouselView(userUrl: userUrl, officialUrl: officialUrl)
        }
        // Case 4: User image and spot image are the same, only show user image
        else if let userUrl = commentImageUrl, let officialUrl = spotImageUrl, userUrl == officialUrl {
            singleImageView(url: userUrl, badgeText: "User Photo")
        }
        // Edge case: Only user image (shouldn't happen for spots, but handle it)
        else if let userUrl = commentImageUrl {
            singleImageView(url: userUrl, badgeText: "User Photo")
        }
    }

    private func singleImageView(url: String, badgeText: String) -> some View {
        ZStack(alignment: .topTrailing) {
            KFImage(URL(string: url))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()

            ImageBadge(text: badgeText)
                .padding(12)
        }
    }

    private func carouselView(userUrl: String, officialUrl: String) -> some View {
        TabView {
            // User photo first
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: userUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()

                ImageBadge(text: "User Photo")
                    .padding(12)
            }
            .tag(0)

            // Official spot photo second
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: officialUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()

                ImageBadge(text: "Official Spot Photo")
                    .padding(12)
            }
            .tag(1)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: height)
    }

    private var placeholderView: some View {
        ZStack {
            categoryColor.opacity(0.3)
            Image(systemName: categoryIcon)
                .font(.system(size: 60))
                .foregroundColor(categoryColor)
        }
        .frame(width: width, height: height)
    }
}
