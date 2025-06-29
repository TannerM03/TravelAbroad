//
//  CitiesView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import SwiftUI

// This view will be the home page where users can select between cities to see reviews for
struct CitiesView: View {
    @StateObject private var vm = CityListViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(searchText: $vm.userSearch)
                    .padding(.bottom, 10)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(vm.sortedCities) { city in
                            let emoji = CountryEmoji.emoji(for: city.country)
                            NavigationLink {
                                RecommendationsView(cityId: city.id, cityName: city.name, imageUrl: city.imageUrl ?? "")
                            } label: {
                                CityCardView(cityName: city.name, imageUrl: city.imageUrl, rating: city.avgRating, flagEmoji: emoji)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Where to next?")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            }
        }
        .task {
            await vm.getCities()
        }
        .overlay {
            if vm.isLoading {
                ProgressView("Loading Cities...")
            } else if vm.cities.isEmpty {
                Text("No cities")
            }
        }
    }
}

#Preview("Loading State") {
    PreviewCitiesView(isLoading: true, cities: [])
}

#Preview("With Cities") {
    PreviewCitiesView(isLoading: false, cities: MockData.sampleCities)
}

#Preview("Empty State") {
    PreviewCitiesView(isLoading: false, cities: [])
}

// MARK: - Preview Helper View
private struct PreviewCitiesView: View {
    let isLoading: Bool
    let cities: [City]
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(searchText: .constant(""))
                    .padding(.bottom, 10)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(cities) { city in
                            let emoji = CountryEmoji.emoji(for: city.country)
                            NavigationLink {
                                Text("Recommendations for \(city.name)")
                            } label: {
                                CityCardView(cityName: city.name, imageUrl: city.imageUrl, rating: city.avgRating, flagEmoji: emoji)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Where to next?")
        }
        .overlay {
            if isLoading {
                ProgressView("Loading Cities...")
            } else if cities.isEmpty {
                Text("No cities")
            }
        }
    }
}

// MARK: - SearchBar

struct SearchBar: View {
    @Binding var searchText: String
    var body: some View {
        TextField("Search for a city or country", text: $searchText)
            .padding(10)
            .padding(.horizontal, 25)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                        .padding(.leading, 8)
                    Spacer()
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "x.circle")
                            .foregroundStyle(.gray)
                            .padding(.trailing, 8)
                    }
                }
            )
            .padding(.horizontal)
    }
}
