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
    @State private var selectedImage2: UIImage?
    @State private var selectedImage3: UIImage?
    @State private var activeImageSlot: Int = 1 // Tracks which image we're selecting (1, 2, or 3)
    @State private var showLeaveRating = false
    @State private var userRating: Double = 5.0
    @FocusState private var isTextFieldFocused: Bool
    @State private var confirmReviewSubmitted: Bool = false
    @State private var showDeleteCommentDialogue = false
    @State private var commentToDelete: Comment? = nil
    @State private var commentToEdit: Comment? = nil
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var nameCopied = false
    @Environment(\.dismiss) var dismiss

    // Safety & Moderation
    @State private var showReportSheet = false
    @State private var commentToReport: Comment? = nil
    @State private var showBlockConfirmation = false
    @State private var userToBlock: Comment? = nil

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
                                selectedImage2 = nil
                                selectedImage3 = nil
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
            .sheet(item: $commentToEdit) { comment in
                EditCommentView(
                    comment: comment,
                    recName: recommendation.name,
                    recId: recommendation.id,
                    vm: vm,
                    onDismiss: { commentToEdit = nil },
                    confirmReviewSubmitted: $confirmReviewSubmitted
                )
            }
            .confirmationDialog("Delete Review", isPresented: $showDeleteCommentDialogue) {
                Button("Delete Review", role: .destructive) {
                    if let comment = commentToDelete {
                        Task {
                            await vm.deleteSpotReview(reviewId: comment.id) {
                                dismiss() // returns to recview if the rec was deleted on comment deletion
                            }
                            commentToDelete = nil
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete your review for \(recommendation.name)?")
            }
            .sheet(isPresented: $showReportSheet) {
                if let comment = commentToReport,
                   let userId = UUID(uuidString: comment.userId),
                   let commentId = UUID(uuidString: comment.id)
                {
                    ReportContentView(
                        reportedUserId: userId,
                        contentType: "comment",
                        contentId: commentId,
                        contentPreview: comment.comment ?? "Comment with rating: \(Int(comment.rating)) stars"
                    )
                }
            }
            .confirmationDialog(
                "Block User?",
                isPresented: $showBlockConfirmation,
                titleVisibility: .visible
            ) {
                Button("Block", role: .destructive) {
                    if let comment = userToBlock,
                       let userId = UUID(uuidString: comment.userId)
                    {
                        Task {
                            await blockUser(userId: userId)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let comment = userToBlock {
                    Text("You will no longer see content from @\(comment.username ?? "this user"). This will also report this user to moderators.")
                }
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
            ImagePicker(image: activeImageSlot == 1 ? $selectedImage : activeImageSlot == 2 ? $selectedImage2 : $selectedImage3)
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

                    Button(action: {
                        UIPasteboard.general.string = recommendation.name
                        withAnimation(.easeInOut(duration: 0.2)) {
                            nameCopied = true
                        }
                        // Reset after 2 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    nameCopied = false
                                }
                            }
                        }
                    }) {
                        Image(systemName: nameCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(nameCopied ? .green : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

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

            if vm.comments.isEmpty {
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
//                        if comment.comment != nil || comment.imageUrl != nil {
                        CommentCardView(
                            comment: comment,
                            viewModel: vm,
                            commentToDelete: $commentToDelete,
                            commentToEdit: $commentToEdit,
                            showDeleteCommentDialogue: $showDeleteCommentDialogue,
                            commentToReport: $commentToReport,
                            showReportSheet: $showReportSheet,
                            userToBlock: $userToBlock,
                            showBlockConfirmation: $showBlockConfirmation
                        )
//                        }
                    }

                    // Load More Button
                    if vm.hasMoreComments {
                        Button(action: {
                            Task {
                                await vm.loadMoreComments(for: recommendation.id)
                            }
                        }) {
                            HStack(spacing: 8) {
                                if vm.isLoadingMore {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                                Text(vm.isLoadingMore ? "Loading..." : "Load More Comments")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
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
                        ForEach(1 ... 5, id: \.self) { i in
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

                    Slider(value: $userRating, in: 0 ... 5, step: 0.1)
                        .accentColor(.yellow)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            // First Image
            HStack(spacing: 12) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image 1 attached")
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if self.selectedImage2 != nil, self.selectedImage3 != nil {
                                self.selectedImage = self.selectedImage2
                                self.selectedImage2 = self.selectedImage3
                                self.selectedImage3 = nil
                            } else if self.selectedImage2 != nil {
                                self.selectedImage = self.selectedImage2
                                self.selectedImage2 = nil
                            } else {
                                self.selectedImage = nil
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
                }

                // Show camera button initially, or green plus if first image is selected but not 3 images yet
                if selectedImage == nil {
                    Button(action: {
                        activeImageSlot = 1
                        showingImagePicker = true
                    }) {
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
                } else if selectedImage2 == nil {
                    Button(action: {
                        activeImageSlot = 2
                        showingImagePicker = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            // Second Image (only show if first image exists)
            if selectedImage != nil && selectedImage2 != nil {
                HStack(spacing: 12) {
                    Image(uiImage: selectedImage2!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image 2 attached")
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if let _ = self.selectedImage3 {
                                self.selectedImage2 = self.selectedImage3
                                self.selectedImage3 = nil
                            } else {
                                self.selectedImage2 = nil
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())

                    // Show camera button or green plus if less than 3 images
                    if selectedImage3 == nil {
                        Button(action: {
                            activeImageSlot = 3
                            showingImagePicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.green)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }

            // Third Image (only show if second image exists)
            if selectedImage != nil && selectedImage2 != nil && selectedImage3 != nil {
                HStack(spacing: 12) {
                    Image(uiImage: selectedImage3!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image 3 attached")
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            self.selectedImage3 = nil
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
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
                }

                // Error message display
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showLeaveRating = false
                            newCommentText = ""
                            selectedImage = nil
                            selectedImage2 = nil
                            selectedImage3 = nil
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
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Review")
                                .font(.body.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isSubmitting)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isSubmitting ? 0.6 : 1.0)
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
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    try await vm.submitComment(
                        recommendationId: recommendation.id,
                        text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                        image: selectedImage,
                        image2: selectedImage2,
                        image3: selectedImage3,
                        rating: userRating
                    )
                } else {
                    try await vm.submitComment(recommendationId: recommendation.id, text: nil, image: selectedImage, image2: selectedImage2, image3: selectedImage3, rating: userRating)
                }
                confirmReviewSubmitted = true

                await vm.refreshRecommendationData()

                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLeaveRating = false
                    }
                    newCommentText = ""
                    selectedImage = nil
                    selectedImage2 = nil
                    selectedImage3 = nil
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Safety Functions

    private func blockUser(userId: UUID) async {
        do {
            try await BlockListManager.shared.blockUser(userId)

            // Remove comments from blocked user immediately
            await MainActor.run {
                vm.comments.removeAll { comment in
                    comment.userId.uppercased() == userId.uuidString.uppercased()
                }
            }

            userToBlock = nil
        } catch {
            print("Error blocking user: \(error)")
        }
    }
}

struct CommentCardView: View {
    let comment: Comment
    let viewModel: CommentsViewModel
    @Binding var commentToDelete: Comment?
    @Binding var commentToEdit: Comment?
    @Binding var showDeleteCommentDialogue: Bool
    @Binding var commentToReport: Comment?
    @Binding var showReportSheet: Bool
    @Binding var userToBlock: Comment?
    @Binding var showBlockConfirmation: Bool
    @State private var selectedImageURL: String?
    @State private var selectedIndex: Int?

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
                    Menu {
                        Button {
                            commentToEdit = comment
                        } label: {
                            Label("Edit Comment", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            commentToDelete = comment
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
                    .zIndex(1)
                } else {
                    // Menu for other users' comments
                    Menu {
                        Button {
                            commentToReport = comment
                            showReportSheet = true
                        } label: {
                            Label("Report Comment", systemImage: "exclamationmark.triangle")
                        }
                        Button(role: .destructive) {
                            userToBlock = comment
                            showBlockConfirmation = true
                        } label: {
                            Label("Block User", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                            .padding(.horizontal, 4)
                    }
                    .zIndex(1)
                }
            }
            .zIndex(1)

            HStack(spacing: 2) {
                // Star rating
                ForEach(1 ... 5, id: \.self) { star in
                    Image(systemName: star <= Int(comment.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                Text(String(format: "%.1f", comment.rating))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            if let commentText = comment.comment {
                Text(commentText)
                    .font(.body)
            }

            // Display images - up to 3
            let imageURLs = [comment.imageUrl, comment.imageUrl2, comment.imageUrl3]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            if !imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(imageURLs.indices, id: \.self) { index in
                            let imagePath = imageURLs[index]

                            if let url = URL(string: imagePath) {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture {
                                        self.selectedIndex = index
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                // Full screen viewer trigger
                .fullScreenCover(item: Binding(
                    get: { selectedIndex.map { _ in IdentifiableURL(url: "") } }, // Dummy URL, we use index
                    set: { if $0 == nil { selectedIndex = nil } }
                )) { _ in
                    if let index = selectedIndex {
                        FullScreenImageViewer(urls: imageURLs, currentIndex: index)
                    }
                }
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
