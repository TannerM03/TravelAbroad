//
//  SpotsGridView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/4/25.
//

import Kingfisher
import SwiftUI

struct ReviewedSpot: Identifiable, Codable {
    let id = UUID()
    let recommendation: Recommendation
    let comment: String?
    let userRating: Double
    let cityName: String
    let country: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case recommendation
        case comment
        case userRating = "rating"
        case cityName
        case country
        case createdAt = "created_at"
    }
}

struct SpotsGridView: View {
    @Bindable var vm: SpotsViewModel

    var body: some View {
        VStack {
            spotsListSection
        }
        .task {
            if vm.userId == nil {
                await vm.fetchUser()
                if let userId = vm.userId, vm.spots.isEmpty {
                    await vm.getReviewedSpots(userId: userId, showLoading: true)
                }
            }
        }
        .onAppear {
            if let userId = vm.userId {
                Task {
                    await vm.getReviewedSpots(userId: userId, showLoading: false)
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
                SpotCard(spot: spot, vm: vm)
            }
        }
        .padding(.horizontal, 16)
    }

    private var overlayContentSection: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading Spots...")
            } else if vm.spots.isEmpty {
                Text("Review your first spot to see them here!")
            }
        }
    }
}

struct SpotCard: View {
    let spot: ReviewedSpot
    @Bindable var vm: SpotsViewModel
    @State private var showDeleteCommentDialogue: Bool = false
    
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
                    Button {
                        showDeleteCommentDialogue = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.leading, 4)
                    }
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
                        Text("Your Rating")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }

                    Spacer()
                }

                Spacer()
            }

            // Comment and timestamp
            HStack(alignment: .bottom) {
                if let comment = spot.comment {
                    Text(comment)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer()

                Text(timeString(from: spot.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.secondary.opacity(0.07), radius: 5, x: 0, y: 3)
        .confirmationDialog("Delete Review", isPresented: $showDeleteCommentDialogue) {
            Button("Delete Review", role: .destructive) {
                Task {
                    await vm.deleteSpot(spot: spot)
                }
            }
        } message: {
            Text("Are you sure you want to delete your review for \(spot.recommendation.name)?")
        }
    }
}

//
// #Preview {
//    SpotsGridView()
// }
