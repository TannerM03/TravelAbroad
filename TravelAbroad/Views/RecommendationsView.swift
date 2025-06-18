//
//  RecommendationsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import SwiftUI
import Kingfisher

struct RecommendationsView: View {
    @StateObject var vm = RecommendationsViewModel()
    let cityId: String
    let cityName: String
    let imageUrl: String
    @State private var selectedCategory: CategoryType? = .activities
    
    var filteredRecommendations: [Recommendation] {
        if let selected = selectedCategory {
            return vm.recommendations.filter { $0.category == selected }
        } else {
            return vm.recommendations
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .ignoresSafeArea(edges: .top)
                    }
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(CategoryType.allCases, id: \.self) { category in
                                        Text(category.rawValue.capitalized)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                            .background(selectedCategory == category ? category.pillColor : Color(.systemGray6))
                                            .foregroundStyle(selectedCategory == category ? .secondary : .primary)
                                            .cornerRadius(10)
                                            .onTapGesture {
                                                withAnimation {
                                                    selectedCategory = category
                                                }
                                            }
                                    }
                                }
                            }.padding()
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredRecommendations) { rec in
                                RecommendationsCardView(rec: rec)
                            }
                        }
                }
            }
            .navigationTitle(cityName)
            .navigationBarTitleDisplayMode(.inline)
        }.task {
            await vm.getRecs(cityId: UUID(uuidString: cityId)!)
        }
    }
}

//#Preview {
//    RecommendationsView(cityId: UUID(uuidString: "49e5f9fb-e080-4365-9de6-cab823acf033")!)
//}

