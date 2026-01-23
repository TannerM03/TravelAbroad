//
//  RecommendationsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Kingfisher
import SwiftUI
import UIKit

struct RecommendationsView: View {
    @State var vm = RecommendationsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddRecommendation = false
    @State private var showRatingTip = false
    let cityId: String
    let cityName: String
    let imageUrl: String
    let userRating: Double?
    let isBucketList: Bool
    let onRatingUpdated: ((Double) -> Void)?
    let cityRating: Double

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading) {
                    cityImageSection
                    categoryFilterSection
                    HStack(spacing: 12) {
                        SearchBar(placeholder: "Search recommendations", searchText: $vm.userSearch)
                        Button {
                            showingAddRecommendation = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 18)
                    recommendationsListSection
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar(.hidden)
        .ignoresSafeArea()
        .swipeToDismiss()
        .overlay {
            if vm.isRatingOverlay {
                ratingPopoverContent
            }
            if showRatingTip {
                ratingTipOverlay
            }
        }
        .task {
            vm.initializeCity(cityId: cityId, cityName: cityName, imageUrl: imageUrl, userRating: userRating, avgRating: cityRating, isBucketList: isBucketList, onRatingUpdated: onRatingUpdated)
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            await vm.reloadAvgRating()
            await vm.fetchUser()
            await vm.getCoordinates(cityId: UUID(uuidString: cityId)!)
        }
        .alert("Rating Submitted!", isPresented: $vm.showSubmittedAlert) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddRecommendation) {
            AddRecommendationView(
                cityId: cityId,
                cityName: cityName,
                selectedCategory: vm.selectedCategory ?? CategoryType.sights
            )
            .onDisappear {
                // Refresh recommendations when returning from add view
                Task {
                    await vm.getRecs(cityId: UUID(uuidString: cityId)!)
                }
            }
        }
        .onChange(of: vm.selectedCategory) { _, _ in
            Task {
                await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            }
        }
        .onChange(of: vm.userSearch) { _, _ in
            Task {
                await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            }
        }
    }

    private var cityImageSection: some View {
        ZStack(alignment: .topLeading) {
            if let url = URL(string: vm.imageUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: 300)
                    .clipped()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue, Color.teal]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 300)
            }

            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)

            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    ratingButton

                    /// Bookmark button - might use this later if i want to have a bucket list somewhere
//                    Button {
//                        Task {
//                            await vm.addOrRemoveFavorite(cityId: UUID(uuidString: vm.cityId) ?? UUID())
//                        }
//                    } label: {
//                        Image(systemName: vm.isFavoriteCity ? "bookmark.fill" : "bookmark")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .padding(12)
//                            .background(.ultraThinMaterial)
//                            .clipShape(Circle())
//                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
//                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                HStack {
                    Text(vm.cityName)
                        .font(.title.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }

    private var ratingButton: some View {
        HStack {
            Button(action: {
                vm.showRatingOverlay()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", vm.avgRating))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
//                    Image(systemName: "person.2.fill")
                    Text("avg.")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .padding(.leading, -3)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            Button(action: {
                vm.showRatingOverlay()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.primary)
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CategoryType.allCases, id: \.self) { category in
                    Text(category.rawValue.capitalized)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(vm.selectedCategory == category ? category.pillColor : Color(.systemGray6))
                        .cornerRadius(20)
                        .foregroundColor(vm.selectedCategory == category ? .white : .primary)
                        .scaleEffect(vm.selectedCategory == category ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.selectedCategory == category)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                vm.selectedCategory = category
                            }
                        }
                }
            }.padding(.vertical)
                .padding(.horizontal, 18)
        }
    }

    private var recommendationsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if vm.isLoading && vm.recommendations.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Loading recommendations...")
                    Spacer()
                }
                .padding(.top, 40)
            } else if !vm.isLoading && vm.recommendations.isEmpty {
                HStack {
                    Spacer()
                    Text("No recommendations found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 40)
            } else {
                ForEach(vm.recommendations) { rec in
                    RecommendationsCardView(rec: rec)
                }

                // Load More Button
                if vm.hasMoreRecs && vm.userSearch.isEmpty {
                    Button(action: {
                        Task {
                            await vm.loadMoreRecs(cityId: UUID(uuidString: cityId)!)
                        }
                    }) {
                        HStack(spacing: 8) {
                            if vm.isLoadingMore {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                            Text(vm.isLoadingMore ? "Loading..." : "Load More Recommendations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .disabled(vm.isLoadingMore)
                    .padding(.top, 8)
                    .padding(.horizontal, 18)
                }
            }
        }.padding(.bottom, 100)
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
                    Text("Rate \(vm.cityName)")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    // if user hasn't rated yet
                    if vm.userRating != nil {
                        // if user has rated
                        Text("Edit your rating")
                            .font(.title3)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("How would you rate this city?")
                            .font(.title3)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(1 ... 5, id: \.self) { i in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    // Update the correct variable based on editing vs adding
                                    if vm.userRating != nil {
                                        vm.userRating = Double(i)
                                    } else {
                                        vm.tempRating = Double(i)
                                    }
                                }
                            }) {
                                if vm.userRating != nil {
                                    Image(systemName: (vm.userRating ?? 5.0) >= Double(i) ? "star.fill" : (vm.userRating ?? 5.0) >= Double(i) - 0.5 ? "star.lefthalf.fill" : "star")
                                        .font(.title)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.yellow)
                                        .scaleEffect((vm.userRating ?? 5.0) >= Double(i) ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.userRating)
                                } else {
                                    Image(systemName: (vm.tempRating ?? 5.0) >= Double(i) ? "star.fill" : (vm.tempRating ?? 5.0) >= Double(i) - 0.5 ? "star.lefthalf.fill" : "star")
                                        .font(.title)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.yellow)
                                        .scaleEffect((vm.tempRating ?? 5.0) >= Double(i) ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.tempRating)
                                }
                            }
                        }
                    }

                    Text(String(format: "%.1f", vm.userRating ?? vm.tempRating ?? 5.0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Slider(value: Binding(
                        get: { vm.userRating != nil ? (vm.userRating ?? vm.tempRating ?? 5.0) : (vm.tempRating ?? 5.0) },
                        set: { vm.userRating != nil ? (vm.userRating = $0) : (vm.tempRating = $0) }
                    ), in: 1 ... 5, step: 0.1)
                        .accentColor(.yellow)
                        .padding(.horizontal, 8)
                }

                HStack(spacing: 24) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.hideRatingOverlay()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())

                    Button("Submit") {
                        Task {
                            if let userRating = vm.userRating {
                                vm.tempRating = userRating
                            }
                            await vm.updateCityReview(userId: vm.userId, cityId: UUID(uuidString: vm.cityId)!, rating: vm.tempRating ?? 5.0)
                            await vm.reloadAvgRating()
                        }
                        vm.showSubmittedAlert = true
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.hideRatingOverlay(resetValues: false) // Don't reset on submit
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
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

    private var ratingTipOverlay: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 20) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.trailing, 80)

                        Text("Tap to rate this city!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.trailing, 35)
                }
                .padding(.top, 20)

                Spacer()
            }
        }
    }
}
