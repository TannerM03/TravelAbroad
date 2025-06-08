//
//  RecommendationsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import SwiftUI

struct RecommendationsView: View {
    @StateObject var vm = RecommendationsViewModel()
    let cityId: String
    let cityName: String
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(CategoryType.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                ForEach(vm.recommendations) { rec in
                    Text(rec.name)
                }
            }
            .navigationTitle(cityName)
        }.task {
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
        }
    }
}

//#Preview {
//    RecommendationsView(cityId: UUID(uuidString: "49e5f9fb-e080-4365-9de6-cab823acf033")!)
//}
