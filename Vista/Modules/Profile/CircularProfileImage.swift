//
//  CircularProfileImage.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/27/25.
//

import SwiftUI

struct CircularProfileImage: View {
    let imageState: ImageState
    let isPopular: Bool

    var body: some View {
        Group {
            switch imageState {
            case .empty:
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                    .clipShape(Circle())
                    .overlay(
                        Group {
                            if isPopular {
                                Circle().stroke(Color.white, lineWidth: 2)
                                Circle().stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .padding(2)
                                Circle().stroke(Color.white, lineWidth: 2)
                                    .padding(6)
                            } else {
                                Circle().stroke(Color.white, lineWidth: 6)
                            }
                        }
                    )
            case .loading:
                ProgressView()
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .overlay(
                        Group {
                            if isPopular {
                                Circle().stroke(Color.white, lineWidth: 1)
                                Circle().stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .padding(3)
                                Circle().stroke(Color.white, lineWidth: 1)
                                    .padding(6)
                            } else {
                                Circle().stroke(Color.white, lineWidth: 6)
                            }
                        }
                    )
            case .failure:
                Circle()
                    .fill(Color.red.opacity(0.4))
                    .overlay(Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.white))
                    .clipShape(Circle())
                    .overlay(
                        Group {
                            if isPopular {
                                Circle().stroke(Color.white, lineWidth: 2)
                                Circle().stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .padding(2)
                                Circle().stroke(Color.white, lineWidth: 2)
                                    .padding(6)
                            } else {
                                Circle().stroke(Color.white, lineWidth: 6)
                            }
                        }
                    )
            }
        }
        .frame(width: 125, height: 125)
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
    CircularProfileImage(imageState: .empty, isPopular: false)
}
