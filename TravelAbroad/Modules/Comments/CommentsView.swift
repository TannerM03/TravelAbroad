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
    @StateObject private var vm = CommentsViewModel()
    @State private var newCommentText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showLeaveRating = false
    @State private var userRating: Double = 5.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            recommendationHeader
                            commentsContentSection
                                .background(Color(.systemBackground))
                            Spacer(minLength: 120)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .navigationBarHidden(true)
                    .blur(radius: showLeaveRating ? 8 : 0)

                    if showLeaveRating {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
            }
        }
        .task {
            vm.recommendation = recommendation
            await vm.fetchComments(for: recommendation.id)
            await vm.fetchUserRating(for: recommendation.id)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private var recommendationHeader: some View {
        ZStack(alignment: .topLeading) {
            if let urlStr = recommendation.imageUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue, Color.teal]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 300)
            }
            
            // Dark gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            VStack {
                HStack {
                    Button(action: {
                        // Navigation back
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("📍")
                            .font(.system(size: 20))
                        Text(recommendation.category.rawValue.capitalized)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(recommendation.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14, weight: .bold))
                            Text(String(format: "%.1f rating", vm.displayedAverageRating))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        Text("💬 \(vm.comments.filter { $0.comment != nil && !$0.comment!.isEmpty }.count) comments")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    
                    if let description = recommendation.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var commentsContentSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("💬 Community Reviews")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(vm.comments.filter { $0.comment != nil && !$0.comment!.isEmpty }.count) reviews")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if vm.comments.filter({ $0.comment != nil && !$0.comment!.isEmpty }).isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("No reviews yet")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Be the first to share your experience!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.comments) { comment in
                            if let _ = comment.comment {
                                CommentCardView(comment: comment)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Leave a Review")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
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
                Text("⭐ Rate \(recommendation.name)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(1 ... 5, id: \.self) { i in
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    userRating = Double(i)
                                }
                            }) {
                                Image(systemName: userRating >= Double(i) ? "star.fill" : "star")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.yellow)
                                    .scaleEffect(userRating >= Double(i) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userRating)
                            }
                        }
                    }

                    Text("\(Int(userRating)) star\(userRating == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
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
                        Text("📸 Image attached")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Tap remove to delete")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()

                    Button("Remove") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            self.selectedImage = nil
                        }
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
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
                    TextField("Share your thoughts... (optional)", text: $newCommentText, axis: .vertical)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(16)
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .lineLimit(3 ... 6)
                        .frame(minHeight: 100)

                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()

                    Button(action: submitRatingAndComment) {
                        Text("Submit Review")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
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
//            await vm.submitRating(for: recommendation.id, rating: Int(userRating))

            if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await vm.submitComment(
                    recommendationId: recommendation.id,
                    text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                    image: selectedImage,
                    rating: Int(userRating)
                )
            } else {
                await vm.submitComment(recommendationId: recommendation.id, text: nil, image: selectedImage, rating: Int(userRating))
            }

            // Optionally refresh the recommendation data in background
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
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.username ?? "Anonymous")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        ForEach(Array(0 ..< comment.rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12, weight: .bold))
                        }
                        
                        ForEach(Array(comment.rating ..< 5), id: \.self) { _ in
                            Image(systemName: "star")
                                .foregroundColor(.yellow.opacity(0.3))
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeAgoText(from: comment.createdAt))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("\(comment.rating)/5")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }

            Text(comment.comment!)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(nil)

            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    isPressed = false
                }
            }
        }
    }

    private func timeAgoText(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func categoryEmoji(for category: CategoryType) -> String {
        switch category {
        case .restaurants: return "🍽️"
        case .hostels: return "🏨"
        case .activities: return "🎯"
        case .nightlife: return "🌃"
        case .sights: return "🏛️"
        case .other: return "📍"
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

#Preview {
    CommentsView(recommendation: Recommendation(
        id: "1",
        userId: "user1",
        cityId: "city1",
        category: .restaurants,
        name: "Amazing Local Restaurant",
        description: "This place serves the most incredible traditional dishes with a modern twist. The atmosphere is cozy and the staff is incredibly friendly.",
        imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
        location: "123 Main St",
        avgRating: 4.8
    ))
}
