//
//  CaptureButton.swift
//  Camera
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation
import SwiftUI

struct CaptureButton: View {
    var action: () -> Void
    var longPressChanged: ((Bool) -> Void)?

    @State
    private var isPressing: Bool = false
    @State
    private var isLongPressing: Bool = false

    private func longPressAndTapGesture(
        onPressingChanged: @escaping (Bool) -> Void,
        onLongPressedChanged: @escaping (Bool) -> Void,
        onTap: @escaping () -> Void
    ) -> some Gesture {
        let longPressGesture = LongPressGesture()
            .onEnded { _ in
                onLongPressedChanged(true)
            }
        let dragGesture = DragGesture(minimumDistance: 0.0)
            .onChanged { _ in
                onPressingChanged(true)
            }
            .onEnded { _ in
                onPressingChanged(false)
                onLongPressedChanged(false)
            }
        let tapGesture = TapGesture()
            .onEnded {
                onTap()
            }
        return longPressGesture
            .simultaneously(with: dragGesture)
            .simultaneously(with: tapGesture)
    }

    var body: some View {
        Circle()
            .foregroundStyle(isLongPressing ? .red : .primary)
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let strokeLineWidthRatio = isPressing ? (isLongPressing ? 0.2 : 0.12) : 0.06
                    let paddingRatio = -0.1
                    Circle()
                        .stroke(.primary, lineWidth: width * strokeLineWidthRatio)
                        .padding(width * paddingRatio)
                }
            }
            .gesture(
                longPressAndTapGesture(
                    onPressingChanged: { isPressing in
                        self.isPressing = isPressing
                    },
                    onLongPressedChanged: { isLongPressing in
                        guard longPressChanged != nil else {
                            return
                        }
                        withAnimation {
                            self.isLongPressing = isLongPressing
                        }
                    },
                    onTap: action
                )
            )
            .onChange(of: isLongPressing) { _, newValue in
                longPressChanged?(newValue)
            }
    }
}

#Preview {
    CaptureButton {
        print("Capture")
    } longPressChanged: { isLongPressing in
        if isLongPressing {
            print("Start recording")
        } else {
            print("Stop recording")
        }
    }
    .frame(width: 60.0)
}
