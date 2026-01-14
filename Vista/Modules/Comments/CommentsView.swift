//
//  CommentsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/10/25.
//

import Kingfisher
import SwiftUI

struct CommentsView: View {
    let recommendation: Recommendation
    @State private var vm = CommentsViewModel()
    @State private var newCommentText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showLeaveRating = false
    @State private var userRating: Double = 5.0
    @FocusState private var isTextFieldFocused: Bool
    @State private var confirmReviewSubmitted: Bool = false
    @State private var showDeleteCommentDialogue = false
    @State private var commentToDelete: Comment? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        recommendationHeader
                        commentsSection
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .toolbar(showLeaveRating ? .hidden : .automatic)
                .navigationTitle("Comments")
                .navigationBarTitleDisplayMode(.inline)
                .blur(radius: showLeaveRating ? 8 : 0)

                if showLeaveRating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLeaveRating = false
                                newCommentText = ""
                                selectedImage = nil
                            }
                        }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showLeaveRating {
                    ratingInputSection
                } else {
                    leaveRatingButton
                }
            }
            .alert("Review Submitted!", isPresented: $confirmReviewSubmitted) {
                Button("OK", role: .cancel) {}
            }
            .confirmationDialog("Delete Review", isPresented: $showDeleteCommentDialogue) {
                Button("Delete Review", role: .destructive) {
                    if let comment = commentToDelete {
                        Task {
                            await vm.deleteSpotReview(reviewId: comment.id)
                            commentToDelete = nil
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete your review for \(recommendation.name)?")
            }
        }
        .task {
            await vm.fetchUser()
            vm.recommendation = recommendation
            await vm.fetchComments(for: recommendation.id)
            await vm.fetchUserRating(for: recommendation.id)

            await vm.refreshRecommendationData()

            if let rec = vm.recommendation {
                let shouldUpdate = rec.summaryUpdatedAt == nil ||
                    (rec.summaryUpdatedAt != nil &&
                        Calendar.current.dateComponents([.day], from: rec.summaryUpdatedAt!, to: Date()).day ?? 0 >= 14)

                if shouldUpdate {
                    await vm.generateSummary(for: rec, comments: vm.comments)
                }
            } else {
                print("not updating summary")
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private var recommendationHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let urlStr = recommendation.imageUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(16)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Text(recommendation.category.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(recommendation.category.pillColor)
                        .cornerRadius(12)
                }

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Avg Rating: \(String(format: "%.1f", vm.displayedAverageRating))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if vm.isGeneratingSummary || (vm.recommendation?.aiSummary != nil && !vm.recommendation!.aiSummary!.isEmpty) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            if vm.isGeneratingSummary {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.purple))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            Text(vm.isGeneratingSummary ? "Generating AI Summary..." : "AI Reviews Summary")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        if vm.isGeneratingSummary {
                            HStack {
                                Text("Analyzing reviews to create a personalized summary...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        } else if let summary = vm.recommendation?.aiSummary {
                            Text(summary)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .cornerRadius(12)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(vm.comments.filter { $0.comment != nil && !$0.comment!.isEmpty }.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Sort picker
            if !vm.comments.isEmpty {
                sortPickerSection
            }

            if vm.comments.filter({ $0.comment != nil && !$0.comment!.isEmpty }).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Be the first to share your thoughts!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.comments) { comment in
                        if comment.comment != nil || comment.imageUrl != nil {
                            CommentCardView(
                                comment: comment,
                                viewModel: vm,
                                commentToDelete: $commentToDelete,
                                showDeleteCommentDialogue: $showDeleteCommentDialogue
                            )
                        }
                    }
                }
            }
        }
    }

    private var sortPickerSection: some View {
        Picker("Sort", selection: $vm.sortOption) {
            ForEach(CommentSortOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.sortOption) { _, newValue in
            vm.updateSortOption(newValue)
        }
    }

    private var leaveRatingButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showLeaveRating = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)

                Text("Leave a Review")
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.body.weight(.bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var ratingInputSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                Text("Rate \(recommendation.name)")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { i in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    userRating = Double(i)
                                }
                            }) {
                                Image(systemName: userRating >= Double(i) ? "star.fill" : userRating >= Double(i) - 0.5 ? "star.leadinghalf.filled" : "star")
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.yellow)
                                    .scaleEffect(userRating >= Double(i) ? 1.1 : 1.0)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(String(format: "%.1f", userRating))
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)

                    Slider(value: $userRating, in: 0...5, step: 0.1)
                        .accentColor(.yellow)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if let selectedImage = selectedImage {
                HStack(spacing: 12) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image attached")
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button("Remove") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            self.selectedImage = nil
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }

            VStack(spacing: 20) {
                ZStack(alignment: .topTrailing) {
                    TextField("Share your thoughts...", text: $newCommentText, axis: .vertical)
                        .font(.body.weight(.medium))
                        .fontDesign(.rounded)
                        .padding(16)
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .lineLimit(3 ... 6)
                        .frame(minHeight: 100)
                        .focused($isTextFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isTextFieldFocused = false
                                }
                            }
                        }

                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "camera.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Circle())
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }

                HStack(spacing: 16) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showLeaveRating = false
                            newCommentText = ""
                            selectedImage = nil
                        }
                    }
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()

                    Button(action: submitRatingAndComment) {
                        Text("Submit Review")
                            .font(.body.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .mask(
            Rectangle()
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .mask(Rectangle().padding(.bottom, -24))
                )
        )
    }

    private func submitRatingAndComment() {
        Task {
            if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await vm.submitComment(
                    recommendationId: recommendation.id,
                    text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                    image: selectedImage,
                    rating: userRating
                )
            } else {
                await vm.submitComment(recommendationId: recommendation.id, text: nil, image: selectedImage, rating: userRating)
            }
            confirmReviewSubmitted = true

            await vm.refreshRecommendationData()

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLeaveRating = false
                }
                newCommentText = ""
                selectedImage = nil
            }
        }
    }
}

struct CommentCardView: View {
    let comment: Comment
    let viewModel: CommentsViewModel
    @Binding var commentToDelete: Comment?
    @Binding var showDeleteCommentDialogue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                NavigationLink(destination: OtherProfileView(selectedUserId: comment.userId)) {
                    HStack(spacing: 8) {
                        // Profile picture with gradient border
                        Group {
                            if let imageUrl = comment.profileImageUrl, let url = URL(string: imageUrl) {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(comment.username?.prefix(1) ?? "?").uppercased())
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .overlay(
                            Group {
                                if comment.isPopular {
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
                                        .padding(3)
                                }
                            }
                        )
                        .frame(width: 32, height: 32)

                        Text(comment.username ?? "Anonymous")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if comment.userId.uppercased() == viewModel.userId?.uuidString {
                    Button {
                        commentToDelete = comment
                        showDeleteCommentDialogue = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.leading, 4)
                    }
                }
            }

            HStack(spacing: 2) {
                // Star rating
                ForEach(1 ... 5, id: \.self) { star in
                    Image(systemName: star <= Int(comment.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
//                ForEach(1 ... 5, id: \.self) { star in
//                    Image(systemName: star <= Int(review.userRating) ? "star.fill" : "star")
//                        .foregroundColor(.yellow)
//                        .font(.caption)
//                }
//                ForEach(Array(0 ..< comment.rating), id: \.self) { _ in
//                    Image(systemName: "star.fill")
//                        .foregroundColor(.yellow)
//                        .font(.caption)
//                }
            }

            if let commentText = comment.comment {
                Text(commentText)
                    .font(.body)
            }

            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
            HStack {
                Text(comment.createdAt.timeAgoOrDateString())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                commentVoteButtons
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var commentVoteButtons: some View {
        HStack(spacing: 12) {
            // Upvote button
            Button {
                Task {
                    await viewModel.toggleVote(commentId: comment.id, voteType: .upvote)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: comment.userVote == .upvote ? "arrowshape.up.fill" : "arrowshape.up")
                        .foregroundColor(comment.userVote == .upvote ? .green : .secondary)
                        .font(.subheadline)
                    Text("\(comment.upvoteCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Downvote button
            Button {
                Task {
                    await viewModel.toggleVote(commentId: comment.id, voteType: .downvote)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: comment.userVote == .downvote ? "arrowshape.down.fill" : "arrowshape.down")
                        .foregroundColor(comment.userVote == .downvote ? .red : .secondary)
                        .font(.subheadline)
                    Text("\(comment.downvoteCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            picker.dismiss(animated: true)
        }
    }
}
