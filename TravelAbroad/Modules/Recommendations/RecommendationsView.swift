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
    let userRating: Double?
    let isBucketList: Bool
    let onRatingUpdated: ((Double) -> Void)?
    @State private var showNavigationTitle = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            cityImageSection
                                .background(
                                    GeometryReader { scrollGeometry in
                                        Color.clear
                                            .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                                    }
                                )
                            contentSection
                                .background(Color(.systemBackground))
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .ignoresSafeArea(edges: .top)
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        // Show navigation title when city name is no longer visible
                        // The city name is roughly 250 points down from the top
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showNavigationTitle = scrollOffset < -200
                        }
                    }
                }
                
                // Dynamic Navigation Bar
                if showNavigationTitle {
                    VStack(spacing: 0) {
                        customNavigationBar
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay {
                if vm.isRatingOverlay {
                    ratingPopoverContent
                }
            }
        }
        .task {
            vm.initializeCity(cityId: cityId, cityName: cityName, imageUrl: imageUrl, userRating: userRating, isBucketList: isBucketList, onRatingUpdated: onRatingUpdated)
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            await vm.fetchUser()
        }
    }

    private var cityImageSection: some View {
        ZStack(alignment: .topLeading) {
            if let url = URL(string: vm.imageUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
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
            
            // Dark gradient overlay at bottom
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            VStack {
                HStack {
                    Button(action: {
                        // Navigation back - handled by NavigationStack
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
                    
                    if !showNavigationTitle {
                        ratingButton
                    }
                    
                    Button {
                        Task {
                            await vm.addOrRemoveFavorite(cityId: UUID(uuidString: vm.cityId) ?? UUID())
                        }
                    } label: {
                        Image(systemName: vm.isFavoriteCity ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🏙️ " + vm.cityName)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Text("Discover amazing places to visit")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var contentSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                categoryFilterSection
                SearchBar(placeholder: "🔍 Search recommendations...", searchText: $vm.userSearch)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            recommendationsListSection
        }
    }
    
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text("🎆 \\(vm.searchedRecs.count) places")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CategoryType.allCases, id: \.self) { category in
                        HStack(spacing: 8) {
                            Text(categoryEmoji(for: category))
                                .font(.system(size: 16))
                            
                            Text(category.rawValue.capitalized)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if vm.selectedCategory == category {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray6))
                                }
                            }
                        )
                        .foregroundColor(vm.selectedCategory == category ? .white : .primary)
                        .scaleEffect(vm.selectedCategory == category ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.selectedCategory == category)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                vm.selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .clipped()
        }
    }

    private var recommendationsListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(vm.searchedRecs) { rec in
                RecommendationsCardView(rec: rec)
            }
        }
        .padding(.horizontal, 20)
    }

    private var ratingButton: some View {
        Button(action: { vm.showRatingOverlay() }) {
            HStack(spacing: 6) {
                if let rating = vm.userRating, rating > 0.0 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else if let rating = userRating, rating > 0.0 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "star")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Rate City")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate this city")
    }
    
    private var ratingPopoverContent: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    vm.hideRatingOverlay()
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("⭐ Rate \\(vm.cityName)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("How would you rate this amazing city?")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(1 ... 5, id: \.self) { i in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    vm.tempRating = Double(i * 2)
                                }
                            }) {
                                Image(systemName: (vm.tempRating ?? 5.0) >= Double(i * 2) ? "star.fill" : (vm.tempRating ?? 5.0) >= Double(i * 2 - 1) ? "star.lefthalf.fill" : "star")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.yellow)
                                    .scaleEffect((vm.tempRating ?? 5.0) >= Double(i * 2) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.tempRating)
                            }
                        }
                    }
                    
                    Text(String(format: "%.1f/10", vm.tempRating ?? 5.0))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Slider(value: Binding(
                        get: { vm.tempRating ?? 5.5 },
                        set: { vm.tempRating = $0 }
                    ), in: 1 ... 10, step: 0.1)
                    .accentColor(.yellow)
                    .padding(.horizontal, 8)
                }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.hideRatingOverlay()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                    
                    Button("Submit Rating") {
                        Task {
                            await vm.updateCityReview(userId: vm.userId, cityId: UUID(uuidString: vm.cityId)!, rating: vm.tempRating ?? 5.0)
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.hideRatingOverlay()
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(32)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
    
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                // Navigation back - handled by NavigationStack
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(vm.cityName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            ratingButton
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .offset(y: 25)
        )
        .padding(.top, 44) // Account for status bar
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

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview("With Recommendations") {
    RecommendationsView(
        cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
        cityName: "Madrid",
        imageUrl: "https://images.unsplash.com/photo-1539037116277-4db20889f2d4",
        userRating: nil,
        isBucketList: false,
        onRatingUpdated: nil
    )
}

#Preview("Empty State") {
    RecommendationsView(
        cityId: "49e5f9fb-e080-4365-9de6-cab823acf033",
        cityName: "Madrid",
        imageUrl: "https://images.unsplash.com/photo-1539037116277-4db20889f2d4",
        userRating: nil,
        isBucketList: true,
        onRatingUpdated: nil
    )
}