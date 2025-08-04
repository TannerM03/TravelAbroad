//
//  AddRecommendationView.swift
//  TravelAbroad
//
//  View for adding new recommendations with Google Places integration
//

import Kingfisher
import SwiftUI

struct AddRecommendationView: View {
    let cityId: String
    let cityName: String
    let selectedCategory: CategoryType
    let cityCoordinates: (Double, Double)

    @StateObject private var viewModel: AddRecommendationViewModel
    @Environment(\.dismiss) private var dismiss

    init(cityId: String, cityName: String, selectedCategory: CategoryType, cityCoordinates: (Double, Double)) {
        self.cityId = cityId
        self.cityName = cityName
        self.selectedCategory = selectedCategory
        self.cityCoordinates = cityCoordinates
        _viewModel = StateObject(wrappedValue: AddRecommendationViewModel(
            cityId: cityId,
            cityName: cityName,
            selectedCategory: selectedCategory,
            cityCoordinates: cityCoordinates
        ))
    }

    @FocusState private var isKeyboardShowing: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    searchSection

                    if let selectedPlace = viewModel.selectedPlace {
                        selectedPlaceSection(place: selectedPlace)

                        starRatingSection
                        descriptionSection

                        submitSection
                    }

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
            .onDisappear {
                // Cancel any pending search when view disappears
                viewModel.searchTask?.cancel()
            }
            .alert("Already Added", isPresented: $viewModel.showDuplicateAlert) {
                Button("OK", role: .cancel) {
                    // Just dismiss the alert
                }
            } message: {
                Text("This recommendation already exists in the app. Search for it to add your own review!")
            }
            .alert("Rating Required", isPresented: $viewModel.showNoRatingAlert) {
                Button("OK", role: .cancel) {
                    // Just dismiss the alert
                }
            } message: {
                Text("Please select a star rating before submitting your recommendation.")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Add \(selectedCategory.rawValue.capitalized)")
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

            Text("Search and add a \(selectedCategory.rawValue) to recommend in \(cityName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedCategory == CategoryType.activities ? "Search for an \(selectedCategory.rawValue)" : "Search for a \(selectedCategory.rawValue)")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Search \(cityName)...", text: $viewModel.searchText)
                        .focused($isKeyboardShowing)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                        .onChange(of: viewModel.searchText) { newValue in
                            // Cancel previous search
                            viewModel.searchTask?.cancel()

                            // Clear results if search is empty
                            if newValue.isEmpty {
                                viewModel.searchResults = []
                                return
                            }

                            // Debounce search with 0.5 second delay
                            viewModel.searchTask = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                                if !Task.isCancelled && !newValue.isEmpty {
                                    await viewModel.performSearch(query: newValue, showLoading: false)
                                }
                            }
                        }
                        .onSubmit {
                            Task {
                                await viewModel.searchPlacesImmediately()
                            }
                        }

                    Button {
                        Task {
                            await viewModel.searchPlacesImmediately()
                        }
                    } label: {
                        Group {
                            if viewModel.isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.purple, Color.blue]),
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSearching || viewModel.searchText.isEmpty)
                }

                if !viewModel.searchResults.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.searchResults) { place in
                            Button(action: {
                                print("👆 AddRecommendation: User selected place: '\(place.name)'")
                                viewModel.selectedPlace = place
                                viewModel.searchResults = []
                                isKeyboardShowing = false
                                print("🏷️ AddRecommendation: Using fixed category: \(selectedCategory.rawValue)")
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(place.name)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    if let address = place.formattedAddress {
                                        HStack(spacing: 6) {
                                            Image(systemName: "location")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }

                                    if let rating = place.rating {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            Text(String(format: "%.1f", rating))
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func selectedPlaceSection(place: GooglePlacesManager.PlaceResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected Place")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = GooglePlacesManager.shared.getFirstPhotoURL(from: place),
                   let url = URL(string: imageUrl)
                {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("No image available")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(place.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let address = place.formattedAddress {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }

//                    if let rating = place.rating {
//                        HStack(spacing: 8) {
//                            Image(systemName: "star.fill")
//                                .foregroundColor(.yellow)
//                                .font(.subheadline)
//                            Text("Google Rating: \(String(format: "%.1f", rating))")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundColor(.secondary)
//                        }
//                    }
                }

                Button("Change Selection") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.selectedPlace = nil
                        viewModel.searchText = ""
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }

    private var starRatingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rating")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Spacer()

                ForEach(1 ... 5, id: \.self) { i in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.userRating = i
                        }
                    }) {
                        Image(systemName: viewModel.userRating >= i ? "star.fill" : "star")
                            .font(.title.weight(.medium))
                            .foregroundColor(.yellow)
                            .scaleEffect(viewModel.userRating >= i ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.userRating)
                    }
                }

                Spacer()
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
                Text(selectedCategory.rawValue.capitalized)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(selectedCategory.pillColor)
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
            Text("Review (Optional)")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Share your thoughts!", text: $viewModel.description, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
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
        .disabled(viewModel.isSubmitting)
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}
