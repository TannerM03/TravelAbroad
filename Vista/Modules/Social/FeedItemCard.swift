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
            // Header and image wrapped in NavigationLink for main content
            NavigationLink(destination: destination) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with city/spot name
                    HStack {
                        if feedItem.type == .spotReview {
                            Text(feedItem.displayName)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
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
                            Text("\(feedItem.displayName), \(feedItem.countryForFlag ?? "")")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if let country = feedItem.countryForFlag {
                                Text(CountryEmoji.emoji(for: country))
                                    .font(.callout)
                            }
                        }
                        
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    // Main image
                    GeometryReader { geometry in
                if let imageUrl = feedItem.displayImageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 300)
                        .clipped()
                } else {
                    // Default image with category icon
                    ZStack {
                        if let category = feedItem.spotCategory {
                            category.pillColor.opacity(0.3)
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }

                        Image(systemName: categoryIcon)
                            .font(.system(size: 60))
                            .foregroundColor(feedItem.spotCategory?.pillColor ?? .gray)
                    }
                    .frame(width: geometry.size.width, height: 300)
                }
            }
            .frame(height: 300)
                }
            }
            .buttonStyle(.plain)

            // Content section (rating, profile, comment, timestamp)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    // Profile picture and username wrapped in NavigationLink
                    NavigationLink(destination: OtherProfileView(selectedUserId: feedItem.userId)) {
                        HStack(spacing: 8) {
                            // Profile picture
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

                            Text(feedItem.username)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    // Rating stars
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

                    // Category pill for spot reviews
                    Spacer()
                    if feedItem.type == .spotReview, let category = feedItem.spotCategory {
                        Text(category.rawValue.capitalized)
                            .foregroundColor(.primary)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(category.pillColor)
                            .cornerRadius(8)
                    }
                }

                // Comment (if exists)
                if feedItem.type == .spotReview, let comment = feedItem.reviewComment, !comment.isEmpty {
                    Text(comment)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                // Timestamp at bottom right
                HStack {
                    Spacer()
                    Text(timeAgoString(from: feedItem.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(feedItem.type == .spotReview ? Color(.secondarySystemGroupedBackground) : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // Time ago formatter
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)

        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        } else {
            return "Just now"
        }
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
