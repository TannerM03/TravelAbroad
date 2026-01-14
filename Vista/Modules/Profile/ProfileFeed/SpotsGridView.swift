//
//  SpotsGridView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/4/25.
//

import Kingfisher
import SwiftUI

struct ReviewedSpot: Identifiable, Codable {
    let id: String
    let recommendation: Recommendation
    let comment: String?
    let userRating: Double
    let cityName: String
    let country: String
    let createdAt: Date

    var upvoteCount: Int = 0
    var downvoteCount: Int = 0
    var netVotes: Int = 0
    var userVote: VoteType? = nil

    init(commentId: String, recommendation: Recommendation, comment: String?, userRating: Double, cityName: String, country: String, createdAt: Date, upvoteCount: Int = 0, downvoteCount: Int = 0, netVotes: Int = 0, userVote: VoteType? = nil) {
        id = commentId
        self.recommendation = recommendation
        self.comment = comment
        self.userRating = userRating
        self.cityName = cityName
        self.country = country
        self.createdAt = createdAt
        self.upvoteCount = upvoteCount
        self.downvoteCount = downvoteCount
        self.netVotes = netVotes
        self.userVote = userVote
    }

    enum CodingKeys: String, CodingKey {
        case id
        case recommendation
        case comment
        case userRating = "rating"
        case cityName
        case country
        case createdAt = "created_at"
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case netVotes = "net_votes"
        case userVote = "user_vote"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        recommendation = try container.decode(Recommendation.self, forKey: .recommendation)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        userRating = try container.decode(Double.self, forKey: .userRating)
        cityName = try container.decode(String.self, forKey: .cityName)
        country = try container.decode(String.self, forKey: .country)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount) ?? 0
        downvoteCount = try container.decodeIfPresent(Int.self, forKey: .downvoteCount) ?? 0
        netVotes = try container.decodeIfPresent(Int.self, forKey: .netVotes) ?? 0

        if let voteString = try container.decodeIfPresent(String.self, forKey: .userVote) {
            userVote = VoteType(rawValue: voteString)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recommendation, forKey: .recommendation)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(userRating, forKey: .userRating)
        try container.encode(cityName, forKey: .cityName)
        try container.encode(country, forKey: .country)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(upvoteCount, forKey: .upvoteCount)
        try container.encode(downvoteCount, forKey: .downvoteCount)
        try container.encode(netVotes, forKey: .netVotes)
        try container.encodeIfPresent(userVote?.rawValue, forKey: .userVote)
    }
}

struct SpotsGridView: View {
    @Bindable var vm: SpotsViewModel
    @Bindable var profileViewModel: ProfileViewModel

    var body: some View {
        VStack {
            spotsListSection
        }
        .task {
            if vm.userId == nil {
                await vm.fetchUser()
                if let userId = vm.userId, vm.reviews.isEmpty {
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
            ForEach(vm.reviews) { review in
                NavigationLink {
                    CommentsView(recommendation: review.recommendation)
                } label: {
                    ReviewCard(review: review, vm: vm, profileVm: profileViewModel)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var overlayContentSection: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading Spots...")
            } else if vm.reviews.isEmpty {
                Text("Review your first spot to see them here!")
            }
        }
    }
}

struct ReviewCard: View {
    let review: ReviewedSpot
    @Bindable var vm: SpotsViewModel
    @Bindable var profileVm: ProfileViewModel
    @State private var showDeleteCommentDialogue: Bool = false

    private var categoryIcon: String {
        switch review.recommendation.category {
        case .all: return "mappin.and.ellipse.circle"
        case .activities: return "figure.hiking"
        case .barsClubs: return "music.note"
        case .restaurants: return "fork.knife"
        case .hostels: return "bed.double"
        case .sights: return "camera"
        case .other: return "location"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with city name and flag
            HStack {
                Text(review.recommendation.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text(CountryEmoji.emoji(for: review.country))
                        .font(.subheadline)
                    Text(review.cityName)
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
                if let urlStr = review.recommendation.imageUrl, let url = URL(string: urlStr) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    ZStack {
                        review.recommendation.category.pillColor.opacity(0.3)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 24))
                            .foregroundColor(review.recommendation.category.pillColor)
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                }

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    // Category pill
                    HStack {
                        Text(review.recommendation.category.rawValue.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(review.recommendation.category.pillColor)
                            .cornerRadius(8)
                        Spacer()
                    }

                    // User rating (stars only)
                    HStack(spacing: 2) {
                        ForEach(1 ... 5, id: \.self) { star in
                            Image(systemName: star <= Int(review.userRating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text(String(format: "%.1f", review.userRating))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        Text("Your Rating")
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
                if let comment = review.comment {
                    Text(comment)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(.top, 12)

            // Timestamp and voting
            HStack(spacing: 12) {
                Text(review.createdAt.timeAgoOrDateString())
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    Task {
                        await vm.toggleVote(spotId: review.id, voteType: .upvote)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: review.userVote == .upvote ? "arrowshape.up.fill" : "arrowshape.up")
                            .foregroundColor(review.userVote == .upvote ? .green : .secondary)
                        Text("\(review.upvoteCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await vm.toggleVote(spotId: review.id, voteType: .downvote)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: review.userVote == .downvote ? "arrowshape.down.fill" : "arrowshape.down")
                            .foregroundColor(review.userVote == .downvote ? .red : .secondary)
                        Text("\(review.downvoteCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }.padding(.top, 5)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.secondary.opacity(0.07), radius: 5, x: 0, y: 3)
        .confirmationDialog("Delete Review", isPresented: $showDeleteCommentDialogue) {
            Button("Delete Review", role: .destructive) {
                Task {
                    await vm.deleteSpot(spot: review)
                    profileVm.spotsReviewed -= 1
                }
            }
        } message: {
            Text("Are you sure you want to delete your review for \(review.recommendation.name)?")
        }
    }
}

//
// #Preview {
//    SpotsGridView()
// }
