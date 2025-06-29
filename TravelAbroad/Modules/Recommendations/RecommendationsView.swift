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
    @State private var selectedCategory: CategoryType? = .activities
    @State private var showRatingOverlay = false
    @State private var selectedRating = 5.0

    var filteredRecommendations: [Recommendation] {
        if let selected = selectedCategory {
            return vm.recommendations.filter { $0.category == selected }
        } else {
            return vm.recommendations
        }
    }

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
                ToolbarItem {
                    Button {
                        showRatingOverlay = true
                    } label: {
                        Image(systemName: "plus.circle")
                        Text("Add rating")
                    }
                }
            }
            .overlay {
                if showRatingOverlay {
                    ratingPopoverContent
                }
            }
        }.task {
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            await vm.fetchUser()
        }
    }
    
    private var cityImageSection: some View {
        Group {
            if let url = URL(string: imageUrl) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .ignoresSafeArea(edges: .top)
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
        }
    }
    
    private var recommendationsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(filteredRecommendations) { rec in
                RecommendationsCardView(rec: rec)
            }
        }
    }
    
    private var ratingPopoverContent: some View {
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
                    showRatingOverlay = false
                }
                .foregroundColor(.secondary)
                
                Button("Submit Rating") {
                    Task {
                        await vm.updateCityReview(userId: vm.userId, cityId: UUID(uuidString: cityId)!, rating: Int(selectedRating))
                    }
                    showRatingOverlay = false
                }
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(width: 280, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 10)
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
                    }
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
