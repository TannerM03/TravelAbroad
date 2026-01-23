//
//  FeedImageCarousel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 12/13/25
//

import Kingfisher
import SwiftUI

struct FeedImageCarousel: View {
    let commentImageUrls: [String]? // User-uploaded images
    let spotImageUrl: String? // Official spot image
    let categoryIcon: String
    let categoryColor: Color
    let width: CGFloat
    let height: CGFloat

    // Helper function to normalize URLs for comparison
    private func normalizeURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }

        // Remove query parameters and fragments
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil

        // Return the path component for comparison (removes domain differences)
        return components?.path.lowercased() ?? urlString.lowercased()
    }

    private func areImagesSame(_ url1: String, _ url2: String) -> Bool {
        return normalizeURL(url1) == normalizeURL(url2)
    }

    var body: some View {
        // Case 1: No images
        if commentImageUrls == nil && spotImageUrl == nil {
            placeholderView
        }
        // Case 2: Only spot image
        else if commentImageUrls == nil, let officialUrl = spotImageUrl {
            singleImageView(url: officialUrl, badgeText: "Official Spot Photo")
        }
        // Case 3: First user image and official image are the same, only show user images
        else if let userUrls = commentImageUrls, let officialUrl = spotImageUrl, !userUrls.isEmpty, areImagesSame(userUrls[0], officialUrl) {
            carouselView(userUrls: userUrls, officialUrl: nil)
        }
        // Case 4: User image and official image are different, show both
        else if let userUrls = commentImageUrls, let officialUrl = spotImageUrl, !userUrls.isEmpty, !areImagesSame(userUrls[0], officialUrl) {
            carouselView(userUrls: userUrls, officialUrl: officialUrl)
        }
        // Edge case: Only user image (shouldn't happen for spots, but handle it)
        else if let userUrls = commentImageUrls {
            singleImageView(url: userUrls[0], badgeText: "User Photo")
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

    private func carouselView(userUrls: [String], officialUrl: String?) -> some View {
        TabView {
            // User photo first
            ForEach(userUrls.indices, id: \.self) { index in
                if userUrls[index] != "" {
                    ZStack(alignment: .topTrailing) {
                        KFImage(URL(string: userUrls[index]))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                        ImageBadge(text: "User Photo")
                            .padding(12)
                    }
                    .tag(index)
                }
            }
            if let officialUrl = officialUrl {
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
                .tag(userUrls.count + 1)
            }
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
