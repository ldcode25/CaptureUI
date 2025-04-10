//
//  CaptureSimulatorOutputController.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import CoreImage
import Foundation
// TODO: Generate video and photo data by the code for simulator.
import SimulatorResources

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

    private var _captureUniqueID: Int64 = 0

    private func nextCaptureUniqueID() -> Int64 {
        _captureUniqueID += 1
        return _captureUniqueID
    }

    func capture() async throws -> CIImage {
        let data = switch lastConfiguredDevice {
        case .frontCamera:
            SimulatorResources.frontPhotoData
        case .backCamera:
            SimulatorResources.backPhotoData
        }

        let image = try await Task.detached {
            guard let image = CIImage(data: data) else {
                throw Error.failed(reason: "Failed to create CIImage")
            }

            return image
        }.value

        return image
    }

    private struct Recording {
        var fileURL: URL
        var continuation: CheckedContinuation<URL, Swift.Error>

        func stop() {
            do {
                let data = SimulatorResources.videoData
                try data.write(to: fileURL)
                continuation.resume(returning: fileURL)
            } catch {
                continuation.resume(throwing: error)
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
