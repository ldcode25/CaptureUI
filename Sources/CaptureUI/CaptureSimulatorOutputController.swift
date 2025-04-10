//
//  CaptureSimulatorOutputController.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import CoreImage
import Foundation

private enum Error: Swift.Error {
    case failed(reason: String)
}

@MainActor
final class CaptureSimulatorOutputController: NSObject {
    private var lastConfiguredDevice: CaptureDevice = .frontCamera

    func captureConfigurations(for device: CaptureDevice) -> [CaptureConfiguration] {
        lastConfiguredDevice = device
        return []
    }

    func capture() async throws -> CIImage {
        let device = lastConfiguredDevice
        return try await Task.detached {
            switch device {
            case .frontCamera:
                SimulatorSupport.shared.frontMockedPhoto
            case .backCamera:
                SimulatorSupport.shared.backMockedPhoto
            }
        }.value
    }

    private struct Recording {
        var fileURL: URL
        var beginTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        var continuation: CheckedContinuation<URL, Swift.Error>

        var durationSinceBeginTime: TimeInterval {
            Date.timeIntervalSinceReferenceDate - beginTime
        }

        func stop() {
            Task.detached {
                do {
                    try await SimulatorSupport.shared.exportMockedVideo(at: fileURL, duration: durationSinceBeginTime)
                    continuation.resume(returning: fileURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private var recording: Recording?

    func startRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            if recording != nil {
                stopRecording()
            }

            let fileName = "\(UUID().uuidString).mov"
            let fileURL = FileManager.default.temporaryDirectory.appending(component: fileName)
            recording = Recording(fileURL: fileURL, continuation: continuation)
        }
    }

    func stopRecording() {
        guard let recording else {
            return
        }
        self.recording = nil

        recording.stop()
    }
}
#endif
