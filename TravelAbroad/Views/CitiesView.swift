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
    
    var body: some View {
        NavigationStack {
            VStack {
                
                SearchBar(searchText: $userSearch)
                    .padding(.bottom, 10)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredCities) { city in
                            let emoji = CountryEmoji.emoji(for: city.country)
                            NavigationLink {
                                RecommendationsView(cityId: city.id, cityName: city.name)
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
                    Image(systemName: "line.horizontal.3.decrease.circle")
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
