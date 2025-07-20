//
//  SwipeToPopGesture.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/19/25.
//

import SwiftUI

struct SwipeToPopGesture: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @State private var dragAmount = CGSize.zero

    func body(content: Content) -> some View {
        content
            .offset(x: dragAmount.width > 0 ? dragAmount.width : 0)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if value.startLocation.x < 50,
                           value.translation.width > 0,
                           abs(value.translation.width) > abs(value.translation.height)
                        {
                            dragAmount = CGSize(width: value.translation.width, height: 0)
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        let velocity = value.predictedEndTranslation.width

                        if value.startLocation.x < 50,
                           abs(value.translation.width) > abs(value.translation.height),
                           value.translation.width > threshold || velocity > 300
                        {
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragAmount = .zero
                            }
                        }
                    }
            )
    }
}

extension View {
    func swipeToDismiss() -> some View {
        modifier(SwipeToPopGesture())
    }
}
