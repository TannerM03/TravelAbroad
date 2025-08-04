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
    @StateObject var vm = RecommendationsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddRecommendation = false
    let cityId: String
    let cityName: String
    let imageUrl: String
    let userRating: Double?
    let isBucketList: Bool
    let onRatingUpdated: ((Double) -> Void)?

    var body: some View {
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
//                                LinearGradient(
//                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
                            .clipShape(Circle())
//                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 10)
                .padding(.horizontal, 18)
                recommendationsListSection
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .toolbar(.hidden)
        .ignoresSafeArea()
        .swipeToDismiss()
        .overlay {
            if vm.isRatingOverlay {
                ratingPopoverContent
            }
        }
        .task {
            vm.initializeCity(cityId: cityId, cityName: cityName, imageUrl: imageUrl, userRating: userRating, isBucketList: isBucketList, onRatingUpdated: onRatingUpdated)
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
            await vm.fetchUser()
            await vm.getCoordinates(cityId: UUID(uuidString: cityId)!)
        }
        .sheet(isPresented: $showingAddRecommendation) {
            AddRecommendationView(
                cityId: cityId,
                cityName: cityName,
                selectedCategory: vm.selectedCategory ?? CategoryType.activities,
                cityCoordinates: (vm.latitude, vm.longitude)
            )
            .onDisappear {
                // Refresh recommendations when returning from add view
                Task {
                    await vm.getRecs(cityId: UUID(uuidString: cityId)!)
                }
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

                    Button {
                        Task {
                            await vm.addOrRemoveFavorite(cityId: UUID(uuidString: vm.cityId) ?? UUID())
                        }
                    } label: {
                        Image(systemName: vm.isFavoriteCity ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .fontWeight(.semibold)
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
        Button(action: { vm.showRatingOverlay() }) {
            HStack(spacing: 6) {
                if let rating = vm.userRating, rating > 0.0 {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.white)
                } else if let rating = userRating, rating > 0.0 {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.white)
                    Text("Rate City")
                        .foregroundColor(.white)
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate this city")
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
            ForEach(vm.searchedRecs) { rec in
                RecommendationsCardView(rec: rec)
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
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("How would you rate this city?")
                        .font(.title3)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
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
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.yellow)
                                    .scaleEffect((vm.tempRating ?? 5.0) >= Double(i * 2) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.tempRating)
                            }
                        }
                    }

                    Text(String(format: "%.1f", vm.tempRating ?? 5.0))
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

                    Slider(value: Binding(
                        get: { vm.tempRating ?? 5.5 },
                        set: { vm.tempRating = $0 }
                    ), in: 1 ... 10, step: 0.1)
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
                            await vm.updateCityReview(userId: vm.userId, cityId: UUID(uuidString: vm.cityId)!, rating: vm.tempRating ?? 5.0)
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.hideRatingOverlay()
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
}
