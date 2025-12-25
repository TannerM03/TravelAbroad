//
//  ImageBadge.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 12/13/25
//

import SwiftUI

struct ImageBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "camera.fill")
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
