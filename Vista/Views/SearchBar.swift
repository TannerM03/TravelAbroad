//
//  SearchBar.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/18/25.
//

import SwiftUI

struct SearchBar: View {
    let placeholder: String
    @Binding var searchText: String
    @State private var isSearching = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))
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
                .font(.body.weight(.medium))
                .fontDesign(.rounded)
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
                            .font(.body.weight(.medium))
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
