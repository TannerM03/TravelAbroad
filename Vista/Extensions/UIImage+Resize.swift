//
//  UIImage+Resize.swift
//  TravelAbroad
//
//  Created by Claude on 3/11/26.
//

import UIKit

extension UIImage {
    /// Resize image to maximum dimension while maintaining aspect ratio
    func resized(to maxDimension: CGFloat, compressionQuality: CGFloat = 0.85) -> Data? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        // Don't upscale images
        guard ratio < 1 else {
            return jpegData(compressionQuality: compressionQuality)
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    /// Resize for profile images (smaller, optimized)
    func resizedForProfile() -> Data? {
        return resized(to: 600, compressionQuality: 0.85)
    }

    /// Resize for city/recommendation images
    func resizedForContent() -> Data? {
        return resized(to: 1500, compressionQuality: 0.82)
    }

    /// Resize for comment images
    func resizedForComment() -> Data? {
        return resized(to: 1000, compressionQuality: 0.82)
    }
}
