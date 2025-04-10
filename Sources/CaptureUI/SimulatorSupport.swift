//
//  SimulatorSupport.swift
//  CaptureUI
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import AVFoundation
import CoreImage
import CoreVideo
import Foundation
import UIKit

private enum Error: Swift.Error {
    case failed(reason: String)
}

extension CIImage {
    func renderUIImage() throws -> UIImage {
        if let cgImage {
            return UIImage(cgImage: cgImage)
        }

        guard let cgImage = CIContext().createCGImage(self, from: extent) else {
            throw Error.failed(reason: "Failed to create CGImage")
        }

        return UIImage(cgImage: cgImage)
    }
}

private extension NSAttributedString {
    static func labelText(string: String, color: UIColor) -> NSAttributedString {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 60.0, weight: .bold),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
        return .init(string: string, attributes: attributes)
    }
}

private extension CVPixelBuffer {
    static func renderText(
        _ text: NSAttributedString,
        backgroundColor: UIColor,
        size: CGSize
    ) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String : Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw Error.failed(reason: "Failed to create pixel buffer.")
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }

        guard let address = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw Error.failed(reason: "Failed to get pixel buffer base address.")
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: address,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            throw Error.failed(reason: "Failed to create CGContext.")
        }

        UIGraphicsPushContext(context)

        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(origin: .zero, size: size)

        backgroundColor.setFill()
        context.fill(rect)

        let textSize = text.size()
        let textRect = CGRect(
            x: (rect.width - textSize.width) * 0.5,
            y: (rect.height - textSize.height) * 0.5,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect)

        UIGraphicsPopContext()

        return pixelBuffer
    }
}

private extension AVAsset {
    func export(to url: URL) async throws {
        let presets = AVAssetExportSession.exportPresets(compatibleWith: self)

        guard let session = AVAssetExportSession(asset: self, presetName: AVAssetExportPreset1280x720) else {
            throw Error.failed(reason: "Failed to initialize session.")
        }

        session.outputFileType = .mov
        session.outputURL = url
        session.canPerformMultiplePassesOverSourceMediaData = true

        try await session.export()

        switch session.status {
        case .completed:
            break
        default:
            if let error = session.error {
                throw error
            } else {
                switch session.status {
                case .failed:
                    throw Error.failed(reason: "Export failed.")
                case .cancelled:
                    throw Error.failed(reason: "Export cancelled.")
                default:
                    throw Error.failed(reason: "Failed to export")
                }
            }
        }
    }
}

final class SimulatorSupport {
    static let shared = SimulatorSupport()

    private func renderMockedPhoto(label string: String) -> CIImage {
        let text = NSAttributedString.labelText(string: string, color: .white)
        let size = CGSize(width: 920.0, height: 1280.0)
        let pixelBuffer = try! CVPixelBuffer.renderText(text, backgroundColor: .black, size: size)
        return CIImage(cvPixelBuffer: pixelBuffer)
    }

    lazy var frontMockedPhoto: CIImage = renderMockedPhoto(label: "Front\nCamera")

    lazy var backMockedPhoto: CIImage = renderMockedPhoto(label: "Back\nCamera")

    private func renderMockedVideo(
        at url: URL,
        duration: TimeInterval
    ) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let size = CGSize(width: 480.0, height: 640.0)

        let outputSettings: [String : Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input.naturalSize = size
        input.transform = .identity
        writer.add(input)

        let inputAdapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: nil
        )

        guard writer.startWriting() else {
            throw Error.failed(reason: "Failed to start AVAssetWriter")
        }

        writer.startSession(atSourceTime: .zero)

        let queue = DispatchQueue(label: "CreateDummyVideoFile.queue", qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        let framePerSecond: Int32 = 15
        let numberOfFrames = Int64(duration * Double(framePerSecond))

        var frame: Int64 = 0
        var lastError: Swift.Error?

        input.requestMediaDataWhenReady(on: queue) {
            var completed = false
            while input.isReadyForMoreMediaData {
                do {
                    let frameTime = CMTime(value: frame, timescale: framePerSecond)

                    let emojiScalar = UnicodeScalar(0x1F42D + UInt32(frame % Int64(framePerSecond)))!
                    let emojiString = String(emojiScalar)
                    let string = "\(emojiString)\n\(String(format: "%03ld", frame))"
                    let text = NSAttributedString.labelText(string: string, color: .white)

                    let pixelBuffer = try CVPixelBuffer.renderText(text, backgroundColor: .black, size: size)

                    inputAdapter.append(pixelBuffer, withPresentationTime: frameTime)

                    frame += 1
                    if frame >= numberOfFrames {
                        completed = true
                        break
                    }
                } catch {
                    lastError = error
                    completed = true
                    break
                }
            }

            if completed {
                input.markAsFinished()
                semaphore.signal()
            }
        }

        semaphore.wait()

        if let lastError {
            writer.cancelWriting()
            throw lastError
        }

        await writer.finishWriting()
    }

    func exportMockedVideo(at url: URL, duration: TimeInterval) async throws {
        let fileName = "\(UUID().uuidString).mov"
        let fileURL = FileManager.default.temporaryDirectory.appending(component: fileName)
        defer {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
            }
        }
        try await renderMockedVideo(at: fileURL, duration: duration)
        let asset = AVURLAsset(url: fileURL)
        try await asset.export(to: url)
    }
}
#endif
