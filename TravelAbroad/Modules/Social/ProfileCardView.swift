//
//  ProfileCardView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/22/25.
//

import SwiftUI
import Kingfisher

struct ProfileCardView: View {
    let profile: OtherProfile
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let imageUrl = profile.imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.title2)
                        )
                }
                
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 2
                    )
                    .frame(width: 76, height: 76)
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text(profile.username)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .foregroundColor(.primary)
    }
        .padding(.vertical, 20)
        .padding(.horizontal, 40)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
    }
}

#Preview {
    ProfileCardView(profile: OtherProfile(id: UUID(), username: "johndoe", imageUrl: nil))
        .padding()
}
