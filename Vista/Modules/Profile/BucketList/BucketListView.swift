//
//  BucketListView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/1/25.
//

import SwiftUI

struct BucketListView: View {
    @ObservedObject var vm: BucketListViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(placeholder: "Search for a city or country", searchText: $vm.userSearch)
                    .padding(.bottom, 10)

                citiesGridSection
            }
            .navigationBarTitle("Bucket List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterToolbarSection
                }
            }
        }
        .task {
            if vm.userId == nil {
                await vm.fetchUser()
                if let userId = vm.userId {
                    await vm.getCities(userId: userId)
                }
            }
        }
        .overlay {
            overlayContentSection
        }
    }

    private var citiesGridSection: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(vm.sortedCities) { city in
                    let emoji = CountryEmoji.emoji(for: city.country)
                    NavigationLink {
                        RecommendationsView(cityId: city.id, cityName: city.name, imageUrl: city.imageUrl ?? "", userRating: nil, isBucketList: city.isBucketList, onRatingUpdated: nil, cityRating: city.avgRating ?? 0.0)
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

#Preview {
    BucketListView(vm: BucketListViewModel())
}
