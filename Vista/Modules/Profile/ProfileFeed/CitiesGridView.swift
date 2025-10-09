//
//  CitiesGridView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/4/25.
//

import SwiftUI

struct CitiesGridView: View {
    @Bindable var vm: TravelHistoryViewModel
    @Bindable var profileViewModel: ProfileViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var cityToDelete: UserRatedCity?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack {
            citiesGridSection
        }

        .task {
            if vm.userId == nil {
                await vm.fetchUser()
                if let userId = vm.userId, vm.cities.count == 0 {
                    await vm.getCities(userId: userId, showLoading: true)
                }
            }
        }
        .onAppear {
            // Set up callback for when cities are deleted
            vm.onCityDeleted = {
                Task {
                    await profileViewModel.refreshTravelStats()
                }
            }

            // Set up callback for when cities are added
            vm.onCityAdded = {
                Task {
                    await profileViewModel.refreshTravelStats()
                }
            }

            // Refresh data when view appears to catch rating updates
            if let userId = vm.userId, vm.cities.count == 0 {
                Task {
                    await vm.getCities(userId: userId, showLoading: false)
                }
            }
        }
        .overlay {
            overlayContentSection
        }
        .confirmationDialog("Delete City Rating", isPresented: $showDeleteConfirmation) {
            Button("Delete Rating", role: .destructive) {
                if let city = cityToDelete {
                    Task {
                        await vm.deleteCityRating(cityId: city.id)
                        cityToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                cityToDelete = nil
            }
        } message: {
            if let city = cityToDelete {
                Text("Are you sure you want to delete your rating for \(city.name)? This action cannot be undone.")
            }
        }
    }

    private var citiesGridSection: some View {
//        ScrollView {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(vm.displayedCities) { city in
                let emoji = CountryEmoji.emoji(for: city.country)

                NavigationLink {
                    RecommendationsView(
                        cityId: city.id.uuidString,
                        cityName: city.name,
                        imageUrl: city.imageUrl ?? "",
                        userRating: city.userRating,
                        isBucketList: false,
                        onRatingUpdated: { newRating in
                            vm.updateCityRating(cityId: city.id.uuidString, newRating: newRating)
                        },
                        cityRating: city.userRating ?? 0.0
                    )
                } label: {
                    ProfileCityCard(cityName: city.name, imageUrl: city.imageUrl, rating: city.userRating, flagEmoji: emoji)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete City Rating", role: .destructive) {
                        cityToDelete = city
                        showDeleteConfirmation = true
                    }
                }
            }
        }
//        }
    }

    private var filterToolbarSection: some View {
        Menu {
            ForEach(CityFilter.allCases) { option in
                Button(action: {
                    vm.filter = option
                }) {
                    Label(option.label, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                Text(vm.filter == .none ? "Filter" : vm.filter.label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                vm.filter == .none ? Color(.systemGray6) : Color.accentColor.opacity(0.15)
            )
            .foregroundStyle(vm.filter == .none ? .primary : Color.accentColor)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: vm.filter)
        .accessibilityLabel("City filter menu")
    }

    private var overlayContentSection: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading Cities...")
            } else if vm.cities.isEmpty {
                Text("Review your first city to see Travel History!")
            }
        }
    }
}
