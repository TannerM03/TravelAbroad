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

    var body: some View {
        
        List(vm.cities) { city in
            Text(city.name)
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
