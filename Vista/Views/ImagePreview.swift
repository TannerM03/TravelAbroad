//
//  ImagePreview.swift
//  Vista
//
//  Created by Tanner Macpherson on 1/18/26.
//

import SwiftUI
import Kingfisher

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: String
}

struct FullScreenImageViewer: View {
    let urls: [String]
    @State var currentIndex: Int // Track which image we are on
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. The Paging View
                TabView(selection: $currentIndex) {
                    ForEach(0..<urls.count, id: \.self) { index in
                        if let imageURL = URL(string: urls[index]) {
                            KFImage(imageURL)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index) // Important for tracking selection
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always)) // Enables swiping
                
                // 2. The Navigation Buttons
                HStack {
                    if currentIndex > 0 {
                        buttonOverlay(icon: "chevron.left") { currentIndex -= 1 }
                    }
                    
                    Spacer()
                    
                    if currentIndex < urls.count - 1 {
                        buttonOverlay(icon: "chevron.right") { currentIndex += 1 }
                    }
                }
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    // Helper for the arrow buttons
    private func buttonOverlay(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
    }
}
