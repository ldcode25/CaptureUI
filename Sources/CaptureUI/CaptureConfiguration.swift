//
//  CaptureConfiguration.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

@preconcurrency
import AVFoundation
import Foundation
import SwiftUI

enum CaptureConfiguration: Equatable, Sendable {
    // This class is used to identify the associated `UIView`.
    @MainActor
    final class AssignVideoPlayerLayer: Equatable, Sendable {
        nonisolated static func == (
            lhs: CaptureConfiguration.AssignVideoPlayerLayer,
            rhs: CaptureConfiguration.AssignVideoPlayerLayer
        ) -> Bool {
            lhs === rhs
        }

        var action: ((AVCaptureVideoPreviewLayer?) -> Void)?
    }

    case videoPreviewLayer(AssignVideoPlayerLayer, device: CaptureDevice)
    case photoOutput(AVCapturePhotoOutput, device: CaptureDevice)
    case movieFileOutput(AVCaptureMovieFileOutput, device: CaptureDevice)

    struct Key: PreferenceKey {
        typealias Value = [CaptureConfiguration]

        static var defaultValue: Value {
            []
        }

        static func reduce(value: inout Value, nextValue: () -> Value) {
            value.append(contentsOf: nextValue())
        }
    }
}
