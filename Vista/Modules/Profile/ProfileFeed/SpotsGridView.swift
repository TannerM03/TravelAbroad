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
    let imageUrl: String?
    let imageUrl2: String?
    let imageUrl3: String?
    let userRating: Double
    let cityName: String
    let country: String
    let createdAt: Date

    var upvoteCount: Int = 0
    var downvoteCount: Int = 0
    var netVotes: Int = 0
    var userVote: VoteType? = nil

    init(commentId: String, recommendation: Recommendation, comment: String?, imageUrl: String?, imageUrl2: String? = nil, imageUrl3: String? = nil, userRating: Double, cityName: String, country: String, createdAt: Date, upvoteCount: Int = 0, downvoteCount: Int = 0, netVotes: Int = 0, userVote: VoteType? = nil) {
        id = commentId
        self.recommendation = recommendation
        self.comment = comment
        self.imageUrl = imageUrl
        self.imageUrl2 = imageUrl2
        self.imageUrl3 = imageUrl3
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
        case imageUrl = "image_url"
        case imageUrl2 = "image_url_2"
        case imageUrl3 = "image_url_3"
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
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imageUrl2 = try container.decodeIfPresent(String.self, forKey: .imageUrl2)
        imageUrl3 = try container.decodeIfPresent(String.self, forKey: .imageUrl3)
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
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
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

            // Load More Button
            if vm.hasMoreSpots {
                Button(action: {
                    if let userId = vm.userId {
                        Task {
                            await vm.loadMoreSpots(userId: userId)
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if vm.isLoadingMore {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        }
                        if !vm.reviews.isEmpty {
                            Text(vm.isLoadingMore ? "Loading..." : "Load More Spots")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .disabled(vm.isLoadingMore)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
    }

    private var overlayContentSection: some View {
        Group {
            if vm.isLoading && vm.reviews.isEmpty {
                ProgressView("Loading Spots...")
            } else if !vm.isLoading && vm.reviews.isEmpty {
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
    @State private var commentToEdit: Comment? = nil
    @State private var confirmReviewSubmitted: Bool = false

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

    // Helper to convert ReviewedSpot to Comment for editing
    private func makeComment(from review: ReviewedSpot) -> Comment {
        return Comment(
            id: review.id,
            userId: vm.userId?.uuidString ?? "",
            recId: review.recommendation.id,
            rating: review.userRating,
            comment: review.comment,
            createdAt: review.createdAt,
            imageUrl: review.imageUrl,
            imageUrl2: review.imageUrl2,
            imageUrl3: review.imageUrl3,
            username: nil
        )
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
                    Menu {
                        Button {
                            commentToEdit = makeComment(from: review)
                        } label: {
                            Label("Edit Comment", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteCommentDialogue = true
                        } label: {
                            Label("Delete Comment", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                            .padding(.horizontal, 4)
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
        .sheet(item: $commentToEdit) { comment in
            EditCommentView(
                comment: comment,
                recName: review.recommendation.name,
                recId: review.recommendation.id,
                vm: CommentsViewModel(),
                onDismiss: {
                    commentToEdit = nil
                    // Refresh the spots list after editing
                    Task {
                        if let userId = vm.userId {
                            await vm.getReviewedSpots(userId: userId, showLoading: false)
                        }
                    }
                },
                confirmReviewSubmitted: $confirmReviewSubmitted
            )
        }
        .alert("Review Updated!", isPresented: $confirmReviewSubmitted) {
            Button("OK", role: .cancel) {}
        }
    }
}

//
// #Preview {
//    SpotsGridView()
// }
