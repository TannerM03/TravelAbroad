//
//  ProfileImage.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/27/25.
//

import SwiftUI

struct CircularProfileImage: View {
    let imageState: ImageState

    var body: some View {
        Group {
            switch imageState {
            case .empty:
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            case .loading:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Circle()
                    .fill(Color.red.opacity(0.4))
                    .overlay(Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.white))
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .shadow(radius: 4)
    }
}

enum ImageState {
    case empty
    case loading(Progress)
    case success(Image)
    case failure(Error)
}

#Preview {
    CircularProfileImage(imageState: .empty)
}
