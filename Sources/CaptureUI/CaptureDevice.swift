//
//  CaptureDevice.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation

public enum CaptureDevice: Sendable, Equatable {
    case frontCamera
    case backCamera

    public mutating func toggle() {
        switch self {
        case .frontCamera:
            self = .backCamera
        case .backCamera:
            self = .frontCamera
        }
    }
}
