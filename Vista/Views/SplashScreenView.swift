//
//  SplashScreenView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 12/13/25
//

import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Background color black or white
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(Color(.systemBackground))
            .ignoresSafeArea()

            // App icon
            VStack(spacing: 20) {
                Image("SplashIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(26)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .scaleEffect(1.0)
//                    .opacity(opacity)
                Text("SideQuest")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
                    .fontWeight(.heavy)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 1.0
//                opacity = 1.0
            }
        }
    }
}
