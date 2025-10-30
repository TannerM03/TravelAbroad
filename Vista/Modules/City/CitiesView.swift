//
//  CitiesView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import SwiftUI

// This view will be the home page where users can select between cities to see reviews for
struct CitiesView: View {
    @Bindable var vm: CityListViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var showRequestCitySheet = false
    private var groupedCities: [String: [City]] {
        Dictionary(grouping: vm.sortedCities) { city in
            city.country
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    headerSection
                    citiesGridSection
                }
            }
            .sheet(isPresented: $showRequestCitySheet) {
                RequestCitySheet { cityName, countryName in
                    Task {
                        await vm.submitCityRequest(city: cityName, country: countryName)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Discover Your Next Trip")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue, Color.teal]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .task {
            if vm.cities.isEmpty {
                await vm.getCities()
            }
        }
        .overlay {
            overlayContentSection
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            SearchBar(placeholder: "Search cities or countries...", searchText: $vm.userSearch)
                .padding(.horizontal, 17)
                .padding(.top, 8)

            Button {
                showRequestCitySheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Request New City")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                }
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.15)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
    }

    private var citiesGridSection: some View {
        LazyVStack(spacing: 24) {
            ForEach(groupedCities.keys.sorted(), id: \.self) { country in
                if let cities = groupedCities[country] {
                    countrySection(country: country, cities: cities)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func countrySection(country: String, cities: [City]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Country header
            HStack {
                Text(CountryEmoji.emoji(for: country))
                    .font(.title2)

                Text(country)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(cities.count) cit\(cities.count == 1 ? "y" : "ies")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }

            // Cities in this country
//                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(cities) { city in
                        let emoji = CountryEmoji.emoji(for: city.country)
                        NavigationLink {
                            RecommendationsView(
                                cityId: city.id,
                                cityName: city.name,
                                imageUrl: city.imageUrl ?? "",
                                userRating: city.userRating,
                                isBucketList: city.isBucketList,
                                onRatingUpdated: { newRating in
                                    vm.updateCityRating(cityId: city.id, newRating: newRating)
                                }, cityRating: city.avgRating ?? 0.0
                            )
                        } label: {
                            CityCardView(cityName: city.name, imageUrl: city.imageUrl, rating: city.avgRating, flagEmoji: emoji)
                        }
                    }
                }
            }
        }
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
                Text("No cities")
            }
        }
    }
}
