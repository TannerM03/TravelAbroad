//
//  EditCommentView.swift
//  Vista
//
//  Created by Tanner Macpherson on 1/15/26.
//

import SwiftUI

struct EditCommentView: View {
    let comment: Comment
    let recName: String
    let recId: String
    @Bindable var vm: CommentsViewModel
    let onDismiss: () -> Void
    @Binding var confirmReviewSubmitted: Bool

    @State private var userRating: Double
    @State private var selectedImage: UIImage?
    @State private var commentText: String
    @State private var showingImagePicker = false
    @State private var imageRemoved = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(comment: Comment, recName: String, recId: String, vm: CommentsViewModel, onDismiss: @escaping () -> Void, confirmReviewSubmitted: Binding<Bool>) {
        self.comment = comment
        self.recName = recName
        self.recId = recId
        self.vm = vm
        self.onDismiss = onDismiss
        self._confirmReviewSubmitted = confirmReviewSubmitted

        // Initialize state with comment data
        self._userRating = State(initialValue: comment.rating)
        self._commentText = State(initialValue: comment.comment ?? "")
        self._selectedImage = State(initialValue: nil)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 20) {
                    Text("\(recName)")
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

                HStack(spacing: 12) {
                    if let selectedImage = selectedImage {
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

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                self.selectedImage = nil
                                self.imageRemoved = true
                            }
                        }label: {
                            Image(systemName: "trash")
                        }
                        .font(.title3.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
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
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)


                VStack(spacing: 20) {
                    ZStack(alignment: .topTrailing) {
                        TextField("Share your thoughts...", text: $commentText, axis: .vertical)
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

                    HStack(spacing: 16) {

                        Button(action: editRatingAndComment) {
                            Text("Submit Changes")
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
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
            .mask(
                Rectangle()
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .mask(Rectangle().padding(.bottom, -24))
                    )
            )
            .navigationTitle("Edit Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                // If user picks a new image, reset the imageRemoved flag
                if newValue != nil {
                    imageRemoved = false
                }
            }
            .task {
                // Load existing image if it exists
                if let imageUrlString = comment.imageUrl,
                   let imageUrl = URL(string: imageUrlString) {
                    Task {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: imageUrl)
                            if let image = UIImage(data: data) {
                                await MainActor.run {
                                    selectedImage = image
                                }
                            }
                        } catch {
                            print("Error loading image: \(error)")
                        }
                    }
                }
            }
        }
    }
    private func editRatingAndComment() {
        Task {
            let textToUpdate = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil

            await vm.updateComment(
                commentId: comment.id,
                recommendationId: recId,
                text: textToUpdate,
                image: selectedImage,
                rating: userRating,
                removeImage: imageRemoved
            )
            
            await vm.refreshRecommendationData()

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDismiss()
                }
            }
        }
    }
}
