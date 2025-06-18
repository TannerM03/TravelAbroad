//
//  CitiesView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import SwiftUI

//This view will be the home page where users can select between cities to see reviews for
struct CitiesView: View {
    @StateObject private var vm = CityListViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var userSearch: String = ""
    @State private var filter: CityFilter = .none
    
    //what will be shown to the user, includes the text the user is searching for and searches for the city name and the country it's in
    var filteredCities: [City] {
        if userSearch.isEmpty {
            return vm.cities
        } else {
            return vm.cities.filter { city in
                city.name.lowercased().contains(userSearch.lowercased()) || city.country.lowercased().contains(userSearch.lowercased())
            }
        }
    }
    
    var sortedCities: [City] {
        if filter == .none {
            return filteredCities
        } else if filter == .best {
            return filteredCities.sorted { $0.avgRating ?? 0 > $1.avgRating ?? 0}
        } else {
            return filteredCities.sorted { $0.avgRating ?? 0 < $1.avgRating ?? 0}
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                SearchBar(searchText: $userSearch)
                    .padding(.bottom, 10)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(sortedCities) { city in
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
                                filter = option
                            }) {
                                Label(option.label, systemImage: option.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline)
                            Text(filter == .none ? "Filter" : filter.label)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            filter == .none ? Color(.systemGray6) : Color.accentColor.opacity(0.15)
                        )
                        .foregroundStyle(filter == .none ? .primary : Color.accentColor)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.18), value: filter)
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

#Preview {
    CitiesView()
}

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
                    }label: {
                        Image(systemName: "x.circle")
                            .foregroundStyle(.gray)
                            .padding(.trailing, 8)
                    }
                }
            )
            .padding(.horizontal)
    }
}

