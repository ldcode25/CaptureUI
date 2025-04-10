//
//  CaptureOutputProxy.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import CoreImage
import Foundation

@MainActor
public struct CaptureOutputProxy {
#if targetEnvironment(simulator)
    var controller: CaptureSimulatorOutputController
#else
    var controller: CaptureOutputController
#endif

    public func capture() async throws -> CIImage {
        try await controller.capture()
    }

    public func startRecording() async throws -> URL {
        try await controller.startRecording()
    }

    public func stopRecording() {
        controller.stopRecording()
    }
}
