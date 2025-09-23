//
//  OtherUserSpotsGridView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/16/25.
//

import Kingfisher
import SwiftUI

struct OtherUserSpotsGridView: View {
    @Bindable var vm: OtherUserSpotsViewModel

    var body: some View {
        VStack {
            spotsListSection
        }
        .task {
            if vm.userId == nil {
                if let _ = vm.userId, vm.spots.isEmpty {
                    await vm.getReviewedSpots(showLoading: true)
                }
            }
        }
        .onAppear {
            if let _ = vm.userId, vm.spots.isEmpty {
                Task {
                    await vm.getReviewedSpots(showLoading: false)
                }
            }
        }
        .overlay {
            overlayContentSection
        }
    }

    private var spotsListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(vm.spots) { spot in
                OtherSpotCard(spot: spot, vm: vm)
            }
        }
        .padding(.horizontal, 16)
    }

    private var overlayContentSection: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading Spots...")
            } else if vm.spots.isEmpty {
                Text("This user hasn't reviewed any spots yet.")
            }
        }
    }
}

struct OtherSpotCard: View {
    let spot: ReviewedSpot
    let vm: OtherUserSpotsViewModel

    private var categoryIcon: String {
        switch spot.recommendation.category {
        case .activities: return "figure.hiking"
        case .nightlife: return "music.note"
        case .restaurants: return "fork.knife"
        case .hostels: return "bed.double"
        case .sights: return "camera"
        case .other: return "location"
        }
    }

    private func timeString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with city name and flag
            HStack {
                Text(spot.recommendation.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text(CountryEmoji.emoji(for: spot.country))
                        .font(.subheadline)
                    Text(spot.cityName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 12)

            // Main content
            HStack(spacing: 12) {
                // Image
                if let urlStr = spot.recommendation.imageUrl, let url = URL(string: urlStr) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    ZStack {
                        spot.recommendation.category.pillColor.opacity(0.3)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 24))
                            .foregroundColor(spot.recommendation.category.pillColor)
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                }

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    // Category pill
                    HStack {
                        Text(spot.recommendation.category.rawValue.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(spot.recommendation.category.pillColor)
                            .cornerRadius(8)
                        Spacer()
                    }

                    // User rating (stars only)
                    HStack(spacing: 2) {
                        ForEach(1 ... 5, id: \.self) { star in
                            Image(systemName: star <= Int(spot.userRating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text("User Rating")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }

                    Spacer()
                }

                Spacer()
            }

            // Comment
            HStack(alignment: .bottom) {
                if let comment = spot.comment {
                    Text(comment)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(.top, 12)

            // timestamp and voting
            HStack(spacing: 12) {
                Text(timeString(from: spot.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                Spacer()
                Button {
                    Task {
                        await vm.toggleVote(spotId: spot.id, voteType: .upvote)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: spot.userVote == .upvote ? "arrowshape.up.fill" : "arrowshape.up")
                            .foregroundColor(spot.userVote == .upvote ? .green : .secondary)
                        Text("\(spot.upvoteCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await vm.toggleVote(spotId: spot.id, voteType: .downvote)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: spot.userVote == .downvote ? "arrowshape.down.fill" : "arrowshape.down")
                            .foregroundColor(spot.userVote == .downvote ? .red : .secondary)
                        Text("\(spot.downvoteCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.secondary.opacity(0.07), radius: 5, x: 0, y: 3)
    }
}

//
// #Preview {
//    SpotsGridView()
// }
