//
//  AddRecommendationView.swift
//  TravelAbroad
//
//  View for adding new recommendations with manual input
//

import SwiftUI

struct AddRecommendationView: View {
    let cityId: String
    let cityName: String
    let selectedCategory: CategoryType

    @State private var viewModel: AddRecommendationViewModel
    @Environment(\.dismiss) private var dismiss

    init(cityId: String, cityName: String, selectedCategory: CategoryType) {
        self.cityId = cityId
        self.cityName = cityName
        self.selectedCategory = selectedCategory
        _viewModel = State(wrappedValue: AddRecommendationViewModel(
            cityId: cityId,
            cityName: cityName,
            selectedCategory: selectedCategory
        ))
    }

    @FocusState private var isKeyboardShowing: Bool
    @State private var showingImagePicker = false
    @State private var activeImageSlot: Int = 1

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    typeOfSpotSection
                    placeInputSection
                    imageSection
                    starRatingSection
                    descriptionSection
                    submitSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Add Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                // Set the dismiss closure for the view model
                viewModel.dismiss = { dismiss() }
            }
            .alert("Rating Required", isPresented: $viewModel.showNoRatingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please select a star rating before submitting your recommendation.")
            }
            .sheet(isPresented: $showingImagePicker) {
                if activeImageSlot == 1 {
                    ImagePicker(image: $viewModel.selectedImage)
                } else if activeImageSlot == 2 {
                    ImagePicker(image: $viewModel.selectedImage2)
                } else {
                    ImagePicker(image: $viewModel.selectedImage3)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Add \(viewModel.selectedCategory.rawValue.capitalized)")
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Search and add a \(viewModel.selectedCategory.rawValue) to recommend in \(cityName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var typeOfSpotSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category*")
                .font(.headline)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CategoryType.allCases.filter { $0 != .all }, id: \.self) { category in
                        Text(category.rawValue.capitalized)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(viewModel.selectedCategory == category ? category.pillColor : Color(.tertiarySystemBackground))
                            .cornerRadius(20)
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                            .scaleEffect(viewModel.selectedCategory == category ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory == category)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.selectedCategory = category
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var placeInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.selectedCategory == CategoryType.all ? "Name of spot*" : "Name of \(viewModel.selectedCategory.rawValue)*")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter place name...", text: $viewModel.placeName)
                .focused($isKeyboardShowing)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .onSubmit {
                    isKeyboardShowing = false
                }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Photo")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                // Plus and trash button when first image is set
                if viewModel.selectedImage != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if let _ = viewModel.selectedImage2 {
                                viewModel.selectedImage = viewModel.selectedImage2
                                viewModel.selectedImage2 = viewModel.selectedImage3
                            } else {
                                viewModel.selectedImage = nil
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.callout.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
                    .padding(.horizontal, 6)
                    if viewModel.selectedImage2 == nil {
                        Button {
                            activeImageSlot = 2
                            showingImagePicker = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }.zIndex(1)

            // First large image
            Button {
                activeImageSlot = 1
                showingImagePicker = true
            } label: {
                if let image = viewModel.selectedImage {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .cornerRadius(16)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("Tap to add photo")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Second image (only show if first image exists)
            if viewModel.selectedImage != nil && viewModel.selectedImage2 != nil {
                HStack(spacing: 12) {
                    Image(uiImage: viewModel.selectedImage2!)
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
                            if let _ = viewModel.selectedImage3 {
                                viewModel.selectedImage2 = viewModel.selectedImage3
                                viewModel.selectedImage3 = nil
                            } else {
                                viewModel.selectedImage2 = nil
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.callout.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())

                    // Show green plus if less than 3 images
                    if viewModel.selectedImage3 == nil {
                        Button(action: {
                            activeImageSlot = 3
                            showingImagePicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.green)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Third image (only show if second image exists)
            if viewModel.selectedImage != nil && viewModel.selectedImage2 != nil && viewModel.selectedImage3 != nil {
                HStack(spacing: 12) {
                    Image(uiImage: viewModel.selectedImage3!)
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
                            viewModel.selectedImage3 = nil
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .font(.callout.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var starRatingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rating*")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.userRating = Double(i)
                            }
                        }) {
                            Image(systemName: viewModel.userRating >= Double(i) ? "star.fill" : viewModel.userRating >= Double(i) - 0.5 ? "star.leadinghalf.filled" : "star")
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundStyle(.yellow)
                                .scaleEffect(viewModel.userRating >= Double(i) ? 1.1 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(String(format: "%.1f", viewModel.userRating))
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)

                Slider(value: $viewModel.userRating, in: 0...5, step: 0.1)
                    .accentColor(.yellow)
                    .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var categoryDisplaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.headline)
                .fontWeight(.semibold)

            HStack {
                Text(viewModel.selectedCategory.rawValue.capitalized)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(viewModel.selectedCategory.pillColor)
                    .cornerRadius(25)
                    .foregroundColor(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Fixed Category")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Based on your filter selection")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Share your thoughts!", text: $viewModel.description, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .lineLimit(3 ... 6)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var submitSection: some View {
        Button {
            viewModel.submitRecommendation()
        } label: {
            HStack(spacing: 12) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .scaleEffect(0.9)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                }
                Text(viewModel.isSubmitting ? "Adding Recommendation..." : "Add Recommendation")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(viewModel.isSubmitting ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isSubmitting)
        }
        .disabled(viewModel.selectedCategory == CategoryType.all || viewModel.isSubmitting || viewModel.placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}
