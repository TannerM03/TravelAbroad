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
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        recommendationHeader
                        commentsSection
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
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
                    
                    VStack {
                        recommendationHeader
                            .padding()
                        Spacer()
                    }
                    .allowsHitTesting(false)
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
        .task {
            await vm.fetchComments(for: recommendation.id)
            await vm.fetchUserRating(for: recommendation.id)
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
                    Text("Avg Rating: \(String(format: "%.1f", recommendation.avgRating))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = recommendation.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
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
            
            if vm.comments.filter({ $0.comment != nil && !$0.comment!.isEmpty }).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
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
                        if let _ = comment.comment {
                            CommentCardView(comment: comment)
                        }
                    }
                }
            }
        }
    }
    
    private var leaveRatingButton: some View {
        Button(action: { 
            withAnimation(.easeInOut(duration: 0.3)) {
                showLeaveRating = true
            }
        }) {
            Text("Leave Rating")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var ratingInputSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Rate \(recommendation.name)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { i in
                            Button(action: { userRating = Double(i) }) {
                                Image(systemName: userRating >= Double(i) ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    Text("\(Int(userRating)) star\(userRating == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            if let selectedImage = selectedImage {
                HStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Remove") {
                        self.selectedImage = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                ZStack(alignment: .trailing) {
                    TextField("Add a comment (optional)", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .frame(minHeight: 80)
                    
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "camera")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .padding(.trailing, 12)
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLeaveRating = false
                            newCommentText = ""
                            selectedImage = nil
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    Button(action: submitRatingAndComment) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .mask(
            Rectangle()
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .mask(Rectangle().padding(.bottom, -20))
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
            }
            else {
                await vm.submitComment(recommendationId: recommendation.id, text: nil, image: selectedImage, rating: Int(userRating))
            }
            
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text(comment.username ?? "Anonymous")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.trailing, 5)
                
                ForEach(Array(0..<comment.rating), id: \.self) { star in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Spacer()
                
                Text(timeAgoText(from: comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.comment!)
                .font(.body)
            
            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func timeAgoText(from date: Date) -> String {
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
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
