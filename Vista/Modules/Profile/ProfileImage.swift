//
//  ProfileImage.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/28/25.
//

import Foundation
import PhotosUI
import SwiftUI

struct ProfileImage: Transferable {
    let image: Image
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw NSError(domain: "Invalid image", code: -1, userInfo: nil)
            }
            return ProfileImage(image: Image(uiImage: uiImage), uiImage: uiImage)
        }
    }
}
