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
    @State private var selectedImage2: UIImage?
    @State private var selectedImage3: UIImage?
    @State private var commentText: String
    @State private var showingImagePicker = false
    @State private var activeImageSlot: Int = 1
    @State private var imageRemoved = false
    @State private var imageRemoved2 = false
    @State private var imageRemoved3 = false
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(comment: Comment, recName: String, recId: String, vm: CommentsViewModel, onDismiss: @escaping () -> Void, confirmReviewSubmitted: Binding<Bool>) {
        self.comment = comment
        self.recName = recName
        self.recId = recId
        self.vm = vm
        self.onDismiss = onDismiss
        _confirmReviewSubmitted = confirmReviewSubmitted

        // Initialize state with comment data
        _userRating = State(initialValue: comment.rating)
        _commentText = State(initialValue: comment.comment ?? "")
        _selectedImage = State(initialValue: nil)
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
                                deleteFirstImage()
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
                                deleteSecondImage()
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

                        // Show green plus if less than 3 images
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
                                deleteThirdImage()
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

                    // Error message display
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 16) {
                        Button(action: editRatingAndComment) {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isSubmitting ? "Updating..." : "Submit Changes")
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
                if activeImageSlot == 1 {
                    ImagePicker(image: $selectedImage)
                } else if activeImageSlot == 2 {
                    ImagePicker(image: $selectedImage2)
                } else {
                    ImagePicker(image: $selectedImage3)
                }
            }
            .task {
                await loadExistingImages()
            }
        }
    }

    private func deleteFirstImage() {
        if selectedImage2 != nil, selectedImage3 != nil {
            selectedImage = selectedImage2
            selectedImage2 = selectedImage3
            selectedImage3 = nil
            imageRemoved = false
            imageRemoved2 = false
            imageRemoved3 = true
        } else if selectedImage2 != nil {
            selectedImage = selectedImage2
            selectedImage2 = nil
            imageRemoved = false
            imageRemoved2 = true
        } else {
            selectedImage = nil
            imageRemoved = true
        }
    }

    private func deleteSecondImage() {
        if let _ = selectedImage3 {
            selectedImage2 = selectedImage3
            selectedImage3 = nil
            imageRemoved2 = false
            imageRemoved3 = true
        } else {
            selectedImage2 = nil
            imageRemoved2 = true
        }
    }

    private func deleteThirdImage() {
        selectedImage3 = nil
        imageRemoved3 = true
    }

    private func loadExistingImages() async {
        // Load image 1
        if let imageUrlString = comment.imageUrl,
           let imageUrl = URL(string: imageUrlString)
        {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        imageRemoved = false
                    }
                }
            } catch {
                print("Error loading image 1: \(error)")
            }
        }

        // Load image 2
        if let imageUrlString = comment.imageUrl2,
           let imageUrl = URL(string: imageUrlString)
        {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage2 = image
                        imageRemoved2 = false
                    }
                }
            } catch {
                print("Error loading image 2: \(error)")
            }
        }

        // Load image 3
        if let imageUrlString = comment.imageUrl3,
           let imageUrl = URL(string: imageUrlString)
        {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage3 = image
                        imageRemoved3 = false
                    }
                }
            } catch {
                print("Error loading image 3: \(error)")
            }
        }
    }

    private func editRatingAndComment() {
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                let textToUpdate = !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil

                // If there's a new image, don't mark it as removed
                let shouldRemoveImage1 = imageRemoved && selectedImage == nil
                let shouldRemoveImage2 = imageRemoved2 && selectedImage2 == nil
                let shouldRemoveImage3 = imageRemoved3 && selectedImage3 == nil

                try await vm.updateComment(
                    commentId: comment.id,
                    recommendationId: recId,
                    text: textToUpdate,
                    image: selectedImage,
                    image2: selectedImage2,
                    image3: selectedImage3,
                    rating: userRating,
                    removeImage: shouldRemoveImage1,
                    removeImage2: shouldRemoveImage2,
                    removeImage3: shouldRemoveImage3
                )

                await vm.refreshRecommendationData()

                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onDismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
