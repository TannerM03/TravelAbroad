//
//  RecommendationsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Kingfisher
import SwiftUI

struct RecommendationsView: View {
    @StateObject var vm = RecommendationsViewModel()
    let cityId: String
    let cityName: String
    let imageUrl: String
    @State private var showRatingOverlay = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    cityImageSection
                    categoryFilterSection
                    recommendationsListSection
                }
            }
            .navigationTitle(cityName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let rating = vm.cityRating, rating > 0.0 {
                        Button(action: { showRatingOverlay = true }) {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit your rating")
                    } else {
                        Button(action: { showRatingOverlay = true }) {
                            HStack(spacing: 6) {
                                Text("Add Rating")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add a rating for this city")
                    }
                }
            }
            .overlay {
                if showRatingOverlay {
                    ratingPopoverContent
                }
            }
        }
        .task {
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            await vm.fetchUser()
            vm.cityRating = await vm.getUserCityRating(for: UUID(uuidString: cityId)!)
        }
    }
    
    private var cityImageSection: some View {
        Group {
            if let url = URL(string: imageUrl) {
                ZStack(alignment: .topTrailing) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .ignoresSafeArea(edges: .top)

                    Button {
                        Task {
                            // do i need to change this UUID() fallback?
                            await vm.addOrRemoveFavorite(cityId: UUID(uuidString: cityId) ?? UUID())
                        }
                    } label: {
                        Image(systemName: vm.isFavorite ? "bookmark.fill" :"bookmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding([.top, .trailing], 16)
                    }
                }
            }
        }
    }

    
    private var categoryFilterSection: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CategoryType.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(vm.selectedCategory == category ? category.pillColor : Color(.systemGray6))
                            .foregroundStyle(vm.selectedCategory == category ? .secondary : .primary)
                            .cornerRadius(10)
                            .onTapGesture {
                                withAnimation {
                                    vm.selectedCategory = category
                                }
                            }
                    }
                }
            }.padding()
        }
    }
    
    private var recommendationsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(vm.filteredRecs) { rec in
                RecommendationsCardView(rec: rec)
            }
        }
    }
    
    private var ratingPopoverContent: some View {
        VStack(spacing: 22) {
            Text("Rate \(cityName)")
                .font(.title2).bold()
                .padding(.top, 10)
            Text("How would you rate this city?")
                .font(.body)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: (vm.cityRating ?? 5.0) >= Double(i * 2) ? "star.fill" : (vm.cityRating ?? 5.0) >= Double(i * 2 - 1) ? "star.lefthalf.fill" : "star")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            vm.cityRating = Double(i * 2)
                        }
                }
            }
            Text(String(format: "%.1f", vm.cityRating ?? 5.0))
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            Slider(value: Binding(
                get: { vm.cityRating ?? 5.5 },
                set: { vm.cityRating = $0 }
            ), in: 1...10, step: 0.1)
                .accentColor(.yellow)
                .padding(.horizontal, 8)
            HStack(spacing: 16) {
                Button("Cancel") {
                    showRatingOverlay = false
                }
                .foregroundColor(.secondary)
                Button("Submit Rating") {
                    Task {
                        await vm.updateCityReview(userId: vm.userId, cityId: UUID(uuidString: cityId)!, rating: vm.cityRating ?? 5.5)
                    }
                    showRatingOverlay = false
                }
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            }
            .padding(.top, 2)
        }
        .padding()
        .frame(width: 320, height: 320)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 14)
        )
    }
}

#Preview("With Recommendations") {
    PreviewRecommendationsView(
        cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
        cityName: "Madrid",
        imageUrl: "https://images.unsplash.com/photo-1539037116277-4db20889f2d4",
        recommendations: MockData.sampleRecommendations
    )
}

#Preview("Empty State") {
    PreviewRecommendationsView(
        cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
        cityName: "Madrid",
        imageUrl: "https://images.unsplash.com/photo-1539037116277-4db20889f2d4",
        recommendations: []
    )
}

// MARK: - Preview Helper View
private struct PreviewRecommendationsView: View {
    let cityId: String
    let cityName: String
    let imageUrl: String
    let recommendations: [Recommendation]
    @State private var selectedCategory: CategoryType? = .activities
    @State private var showRatingPopover = false
    @State private var selectedRating = 5.0
    
    var filteredRecommendations: [Recommendation] {
        if let selected = selectedCategory {
            return recommendations.filter { $0.category == selected }
        } else {
            return recommendations
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .ignoresSafeArea(edges: .top)
                    }
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CategoryType.allCases, id: \.self) { category in
                                    Text(category.rawValue.capitalized)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == category ? category.pillColor : Color(.systemGray6))
                                        .foregroundStyle(selectedCategory == category ? .secondary : .primary)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedCategory = category
                                            }
                                        }
                                }
                            }
                        }.padding()
                    }.padding()
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredRecommendations) { rec in
                            RecommendationsCardView(rec: rec)
                        }
                    }
                    if filteredRecommendations.isEmpty {
                        Text("No recommendations for this category")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle(cityName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        showRatingPopover = true
                    } label: {
                        Image(systemName: "plus.circle")
                        Text("Add rating")
                    }
                    .popover(isPresented: $showRatingPopover) {
                        previewRatingPopoverContent
                    }
                }
            }
        }
    }
    
    private var previewRatingPopoverContent: some View {
        VStack(spacing: 16) {
            Text("Rate \(cityName)")
                .font(.headline)
            
            Text("How would you rate this city?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Rating", selection: $selectedRating) {
                ForEach(Array(stride(from: 1.0, through: 10.0, by: 0.1)), id: \.self) { rating in
                    Text(String(format: "%.1f", rating)).tag(rating)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    showRatingPopover = false
                }
                .foregroundColor(.secondary)
                
                Button("Submit Rating") {
                    showRatingPopover = false
                }
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(width: 280, height: 240)
    }
}

