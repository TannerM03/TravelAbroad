//
//  CitiesView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import SwiftUI

// This view will be the home page where users can select between cities to see reviews for
struct CitiesView: View {
    @ObservedObject var vm: CityListViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        citiesGridSection
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarHidden(true)
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
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✈️ Ready to explore?")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("Discover Amazing Cities")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue, Color.teal]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Spacer()
                filterToolbarSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            SearchBar(placeholder: "Search cities or countries...", searchText: $vm.userSearch)
                .padding(.horizontal, 20)
        }
    }
    
    private var citiesGridSection: some View {
        LazyVStack(spacing: 24) {
            if vm.userSearch.isEmpty {
                // Group cities by country when not searching
                ForEach(groupedCities.keys.sorted(), id: \.self) { country in
                    if let cities = groupedCities[country] {
                        countrySection(country: country, cities: cities)
                    }
                }
            } else {
                // Show regular grid when searching
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(vm.sortedCities) { city in
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
                                }
                            )
                        } label: {
                            CityCardView(cityName: city.name, imageUrl: city.imageUrl, rating: city.avgRating, flagEmoji: emoji)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var groupedCities: [String: [City]] {
        Dictionary(grouping: vm.sortedCities) { city in
            city.country
        }
    }
    
    private func countrySection(country: String, cities: [City]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Country header
            HStack {
                Text(CountryEmoji.emoji(for: country))
                    .font(.system(size: 28))
                
                Text(country)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(cities.count) cit\(cities.count == 1 ? "y" : "ies")")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            
            // Cities in this country
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
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
                            }
                        )
                    } label: {
                        CityCardView(cityName: city.name, imageUrl: city.imageUrl, rating: city.avgRating, flagEmoji: emoji)
                    }
                }
            }
        }
    }

    private var filterToolbarSection: some View {
        Menu {
            ForEach(CityFilter.allCases) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        vm.filter = option
                    }
                }) {
                    Label(option.label, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        vm.filter == .none ? 
                        AnyShapeStyle(Color.primary) :
                        AnyShapeStyle(LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                
                Text(vm.filter == .none ? "Filter" : vm.filter.label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        vm.filter == .none ? 
                        AnyShapeStyle(Color.primary) :
                        AnyShapeStyle(LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if vm.filter == .none {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.systemGray6).opacity(0.8))
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ), lineWidth: 1
                                    )
                            )
                    }
                }
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.filter)
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

// MARK: - SearchBar

struct SearchBar: View {
    let placeholder: String
    @Binding var searchText: String
    @State private var isSearching = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        isSearching ? 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isSearching ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSearching)
                
                TextField(placeholder, text: $searchText) { editing in
                    withAnimation(.spring(response: 0.3)) {
                        isSearching = editing
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .keyboardType(.webSearch)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isSearching = true
                    }
                }
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSearching ? 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSearching ? 2 : 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearching)
    }
}
