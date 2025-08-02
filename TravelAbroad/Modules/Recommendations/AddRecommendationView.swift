//
//  AddRecommendationView.swift
//  TravelAbroad
//
//  View for adding new recommendations with Google Places integration
//

import SwiftUI
import Kingfisher

struct AddRecommendationView: View {
    let cityId: String
    let cityName: String
    let selectedCategory: CategoryType
    let cityCoordinates: (Double, Double)
    
    @StateObject private var viewModel = AddRecommendationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedPlace: GooglePlacesManager.PlaceResult?
    @State private var description = ""
    @State private var isSearching = false
    @State private var searchResults: [GooglePlacesManager.PlaceResult] = []
    @State private var isSubmitting = false
    @State private var searchTask: Task<Void, Never>?
    @State private var userRating: Double = 0.0
    @FocusState private var isKeyboardShowing: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
//                    headerSection
                    searchSection
                    
                    if let selectedPlace = selectedPlace {
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
            .onDisappear {
                // Cancel any pending search when view disappears
                searchTask?.cancel()
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
                    TextField("Search \(cityName)...", text: $searchText)
                        .focused($isKeyboardShowing)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: searchText) { newValue in
                            // Cancel previous search
                            searchTask?.cancel()
                            
                            // Clear results if search is empty
                            if newValue.isEmpty {
                                searchResults = []
                                return
                            }
                            
                            // Debounce search with 0.5 second delay
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                
                                if !Task.isCancelled && !newValue.isEmpty {
                                    await performSearch(query: newValue, showLoading: false)
                                }
                            }
                        }
                        .onSubmit {
                            Task {
                                await searchPlacesImmediately()
                            }
                        }
                    
                    Button {
                        Task {
                            await searchPlacesImmediately()
                        }
                    } label: {
                        Group {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.tertiary)
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.purple, Color.blue]),
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
                        .cornerRadius(12)
                    }
                    .disabled(isSearching || searchText.isEmpty)
                }
                
                if !searchResults.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(searchResults) { place in
                            Button(action: {
                                print("👆 AddRecommendation: User selected place: '\(place.name)'")
                                selectedPlace = place
                                searchResults = []
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(16)
    }
    
    private func selectedPlaceSection(place: GooglePlacesManager.PlaceResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected Place")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = GooglePlacesManager.shared.getFirstPhotoURL(from: place),
                   let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
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
                        selectedPlace = nil
                        searchText = ""
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
        HStack(spacing: 12) {
            ForEach(1 ... 5, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        userRating = Double(i)
                    }
                }) {
                    Image(systemName: userRating >= Double(i) ? "star.fill" : "star")
                        .font(.title.weight(.medium))
                        .foregroundColor(.yellow)
                        .scaleEffect(userRating >= Double(i) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userRating)
                }
            }
        }
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
            
            TextField("Share your thoughts!", text: $description, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .lineLimit(3...6)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var submitSection: some View {
        Button{
            if userRating >= 0.5 {
                submitRecommendation()
            } else {
                //user hasn't selected  a rating yet
            }
        } label: {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.9)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                }
                Text(isSubmitting ? "Adding Recommendation..." : "Add Recommendation")
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
            .scaleEffect(isSubmitting ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSubmitting)
        }
        .disabled(isSubmitting)
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    // Immediate search (button tap or Enter key)
    private func searchPlacesImmediately() async {
        searchTask?.cancel()
        await performSearch(query: searchText, showLoading: true)
    }
    
    // Core search logic
    private func performSearch(query: String, showLoading: Bool) async {
        guard !query.isEmpty else {
            print("AddRecommendation: Search text is empty, skipping search")
            await MainActor.run {
                searchResults = []
                if showLoading { isSearching = false }
            }
            return
        }
        
        if showLoading {
            await MainActor.run {
                isSearching = true
            }
        }
        
        print("🔍 AddRecommendation: Starting place search for: '\(query)'")
        
        do {
            let categoryQuery = "\(query) \(getCategorySearchTerm())"
            
            // Use city coordinates if available, otherwise nil for global search
            let coordinates: (Double, Double)? = (cityCoordinates.0 != 0.0 && cityCoordinates.1 != 0.0) ? cityCoordinates : nil
            
            if let coords = coordinates {
                print("🌍 AddRecommendation: Using location-based search within 100 miles of \(cityName) (\(coords.0), \(coords.1))")
            } else {
                print("⚠️ AddRecommendation: No valid coordinates for \(cityName), using global search")
            }
            
            let results = try await GooglePlacesManager.shared.searchPlaces(
                query: categoryQuery,
                coordinates: coordinates
            )
            
            await MainActor.run {
                searchResults = Array(results.prefix(5)) // Limit to 5 results
                if showLoading { isSearching = false }
                print("✅ AddRecommendation: Search completed, found \(searchResults.count) results")
            }
        } catch {
            await MainActor.run {
                if showLoading { isSearching = false }
                print("❌ AddRecommendation: Error searching places: \(error)")
            }
        }
    }
    
    // Legacy method for compatibility
    private func searchPlaces() {
        Task {
            await performSearch(query: searchText, showLoading: true)
        }
    }
    
    private func submitRecommendation() {
        guard let place = selectedPlace else {
            print("❌ AddRecommendation: No place selected for submission")
            return
        }
        
        print("AddRecommendation: Submitting recommendation for place: '\(place.name)'")
        print("AddRecommendation: City: \(cityName), Category: \(selectedCategory.rawValue)")
        print("AddRecommendation: Description: '\(description.isEmpty ? "none" : description)'")
        
        isSubmitting = true
        
        Task {
            do {
                let imageUrl = GooglePlacesManager.shared.getFirstPhotoURL(from: place)
                print("AddRecommendation: Image URL obtained: \(imageUrl ?? "none")")
                
                let recommendation = try await SupabaseManager.shared.createRecommendation(
                    cityId: cityId,
                    name: place.name,
                    description: nil,
                    category: selectedCategory,
                    location: place.formattedAddress,
                    imageUrl: imageUrl,
                    googlePlaceId: place.placeId
                )
                
                await MainActor.run {
                    isSubmitting = false
                    print("✅ AddRecommendation: Successfully created recommendation with ID: \(recommendation.id)")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("❌ AddRecommendation: Error creating recommendation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getCategorySearchTerm() -> String {
        switch selectedCategory {
        case .restaurants:
            return "restaurant"
        case .hostels:
            return "hotel"
        case .activities:
            return "activity"
        case .nightlife:
            return "bar"
        case .sights:
            return "attraction"
        case .other:
            return ""
        }
    }
}

@MainActor
class AddRecommendationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let placesManager = GooglePlacesManager.shared
    private let supabaseManager = SupabaseManager.shared
}

