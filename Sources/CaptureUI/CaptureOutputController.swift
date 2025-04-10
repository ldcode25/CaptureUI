//
//  CaptureOutputController.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import AVFoundation
@preconcurrency
import CoreImage
import Foundation
import Logger

private enum Error: Swift.Error {
    case failed(reason: String)
}

private extension AVCapturePhoto {
    var orientation: CGImagePropertyOrientation? {
        // Can't `as? CGImagePropertyOrientation` which always failed.
        guard let rawValue = metadata[kCGImagePropertyOrientation as String] as? UInt32 else {
            return nil
        }
        return CGImagePropertyOrientation(rawValue: rawValue)
    }

    var ciImage: CIImage? {
        guard let cgImage = cgImageRepresentation() else {
            return nil
        }

        var image = CIImage(cgImage: cgImage)

        if let orientation {
            image = image.oriented(orientation)
        }

        return image
    }
}

// TODO: output may need to handle on background thread instead.
@MainActor
final class CaptureOutputController: NSObject {
    private let movieFileOutput: AVCaptureMovieFileOutput
    private let photoOutput: AVCapturePhotoOutput

    override init() {
        // TODO: Ensure thread safety expectation for these output objects.
        // There is a warning appears when these are initialized on main thread due to I/O work.
        movieFileOutput = AVCaptureMovieFileOutput()
        photoOutput = AVCapturePhotoOutput()

        super.init()
    }

    func captureConfigurations(for device: CaptureDevice) -> [CaptureConfiguration] {
        [
            .photoOutput(photoOutput, device: device),
            .movieFileOutput(movieFileOutput, device: device)
        ]
    }

    private var continuations: [CaptureOutputIdentifier : Any] = [:]

    func capture() async throws -> CIImage {
        try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()

            let identifier = CaptureOutputIdentifier(settings.uniqueID)
            continuations[identifier] = continuation

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func startRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let fileName = "\(UUID().uuidString).mov"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            let identifier = CaptureOutputIdentifier(url)
            continuations[identifier] = continuation

            movieFileOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    func stopRecording() {
        movieFileOutput.stopRecording()
    }
}

extension CaptureOutputController: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Swift.Error)?
    ) {
        Task { @MainActor in
            let uniqueID = photo.resolvedSettings.uniqueID
            let identifier = CaptureOutputIdentifier(uniqueID)

            guard let continuation = continuations[identifier] as? CheckedContinuation<CIImage, Swift.Error> else {
                fatalError("Must not reach here.")
            }
            continuations.removeValue(forKey: identifier)

            if let error {
                continuation.resume(throwing: error)
                return
            }

            guard let image = photo.ciImage else {
                continuation.resume(throwing: Error.failed(reason: "No CIImage for photo"))
                return
            }

            continuation.resume(returning: image)
        }
    }
}

extension CaptureOutputController: AVCaptureFileOutputRecordingDelegate {
    public nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Swift.Error)?
    ) {
        Task { @MainActor in
            let identifier = CaptureOutputIdentifier(outputFileURL)

            guard let continuation = continuations[identifier] as? CheckedContinuation<URL, Swift.Error> else {
                fatalError("Must not reach here.")
            }
            continuations.removeValue(forKey: identifier)

            if let error {
                continuation.resume(throwing: error)
                return
            }

            continuation.resume(returning: outputFileURL)
        }
    }
}
