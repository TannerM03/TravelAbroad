//
//  FeedItemCard.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 10/13/25
//

import Kingfisher
import SwiftUI

struct FeedItemCard<Destination: View>: View {
    let feedItem: FeedItem
    let destination: Destination

    private var categoryIcon: String {
        guard let category = feedItem.spotCategory else { return "mappin.circle" }
        switch category {
        case .all: return "mappin.and.ellipse.circle"
        case .activities: return "figure.hiking"
        case .nightlife: return "music.note"
        case .restaurants: return "fork.knife"
        case .hostels: return "bed.double"
        case .sights: return "camera"
        case .other: return "location"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section - profile + username for both types
            // City name centered for city ratings
            if feedItem.type == .cityRating {
                HStack {
                    Spacer()
                    Text("\(feedItem.displayName), \(feedItem.countryForFlag ?? "")")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if let country = feedItem.countryForFlag {
                        Text(CountryEmoji.emoji(for: country))
                            .font(.callout)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
            }
            VStack(alignment: .leading, spacing: feedItem.type == .cityRating ? 4 : 8) {
                HStack(alignment: .center, spacing: 10) {
                    NavigationLink(destination: OtherProfileView(selectedUserId: feedItem.userId)) {
                        HStack(spacing: 8) {
                            // Profile picture with gradient border
                            Group {
                                if let imageUrl = feedItem.userImageUrl, let url = URL(string: imageUrl) {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 28, height: 28)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(String(feedItem.username.prefix(1)).uppercased())
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .overlay(
                                Group {
                                    if feedItem.isUserPopular {
                                        Circle().stroke(Color.white, lineWidth: 1)
                                        Circle().stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .padding(1)
                                        Circle().stroke(Color.white, lineWidth: 0.75)
                                            .padding(2.75)
                                    }
                                }
                            )
                            .frame(width: 28, height: 28)

                            Text(feedItem.username)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)

                    Spacer()

                    // City name on right for spot reviews only
                    if feedItem.type == .spotReview {
                        if let locationText = feedItem.locationText {
                            HStack(spacing: 4) {
                                Text(locationText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let country = feedItem.countryForFlag {
                                    Text(CountryEmoji.emoji(for: country))
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        HStack(spacing: 10) {
                            HStack(spacing: 2) {
                                ForEach(0 ..< 5) { index in
                                    Image(systemName: starIcon(for: index, rating: feedItem.rating))
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                Text(String(format: "%.1f", feedItem.rating))
                                    .font(.caption.weight(.medium))
                                    .fontDesign(.rounded)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, feedItem.type == .cityRating ? 4 : 10)
            .padding(.bottom, feedItem.type == .cityRating ? 10 : 10)

            // Image and content wrapped in NavigationLink
            NavigationLink(destination: destination) {
                VStack(alignment: .leading, spacing: 0) {
                    // Main image
                    GeometryReader { geometry in
                        if feedItem.type == .spotReview {
                            // Use carousel for spot reviews
                            FeedImageCarousel(
                                commentImageUrl: feedItem.commentImageUrl,
                                spotImageUrl: feedItem.spotImageUrl,
                                categoryIcon: categoryIcon,
                                categoryColor: feedItem.spotCategory?.pillColor ?? .gray,
                                width: geometry.size.width,
                                height: 300
                            )
                        } else {
                            if let imageUrl = feedItem.displayImageUrl, let url = URL(string: imageUrl) {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 300)
                                    .clipped()
                            } else {
                                // City placeholder
                                ZStack {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )

                                    Image(systemName: categoryIcon)
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                }
                                .frame(width: geometry.size.width, height: 300)
                            }
                        }
                    }
                    .frame(height: 300)

                    // Content section for spot reviews (inside NavigationLink)
                    if feedItem.type == .spotReview {
                        VStack(alignment: .leading, spacing: 10) {
                            // Spot name on left, category pill on right
                            HStack {
                                Text(feedItem.displayName)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                if let category = feedItem.spotCategory {
                                    Text(category.rawValue.capitalized)
                                        .foregroundColor(.primary)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(category.pillColor)
                                        .cornerRadius(8)
                                }
                            }

                            // Rating stars below spot name
                            HStack(spacing: 2) {
                                ForEach(0 ..< 5) { index in
                                    Image(systemName: starIcon(for: index, rating: feedItem.rating))
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                Text(String(format: "%.1f", feedItem.rating))
                                    .font(.caption.weight(.medium))
                                    .fontDesign(.rounded)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }

                            // Comment (if exists)
                            if let comment = feedItem.reviewComment, !comment.isEmpty {
                                Text(comment)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // Timestamp (outside NavigationLink for spot reviews)
            if feedItem.type == .spotReview {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Text(feedItem.createdAt.timeAgoOrDateString())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            } else {
                // Content section for city ratings (outside NavigationLink)
                VStack(alignment: .leading, spacing: 10) {
                    // For city ratings: rating stars and date on same line
                    HStack(spacing: 10) {
//                        HStack(spacing: 2) {
//                            ForEach(0 ..< 5) { index in
//                                Image(systemName: starIcon(for: index, rating: feedItem.rating))
//                                    .font(.caption)
//                                    .foregroundColor(.yellow)
//                            }
//                            Text(String(format: "%.1f", feedItem.rating))
//                                .font(.caption.weight(.medium))
//                                .fontDesign(.rounded)
//                                .foregroundColor(.secondary)
//                                .lineLimit(1)
//                                .fixedSize()
//                        }

                        Spacer()

                        Text(feedItem.createdAt.timeAgoOrDateString())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(feedItem.type == .spotReview ? Color(.secondarySystemGroupedBackground) : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            Group {
                if feedItem.type == .cityRating {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.primary,
                                lineWidth: 2)
                }
            }
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // Helper function to determine which star icon to show
    private func starIcon(for index: Int, rating: Double) -> String {
        let position = Double(index) + 1.0

        if rating >= position {
            return "star.fill"
        } else if rating >= position - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
