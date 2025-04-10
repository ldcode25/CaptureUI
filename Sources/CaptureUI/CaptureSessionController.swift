//
//  CaptureSessionController.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

@preconcurrency
import AVFoundation
import Combine
import Foundation
import Logger

extension AVCaptureSession: @retroactive @unchecked Sendable {
}

private enum Error: Swift.Error {
    case failed(reason: String)
}

private extension CaptureDevice {
    var position: AVCaptureDevice.Position {
        switch self {
        case .frontCamera:
            .front
        case .backCamera:
            .back
        }
    }
}

private extension AVCaptureDevice.Position {
    var captureDevice: CaptureDevice? {
        switch self {
        case .front:
            .frontCamera
        case .back:
            .backCamera
        case .unspecified:
            nil
        @unknown default:
            nil
        }
    }
}

private extension AVCaptureSession {
    func previewLayerForCaptureDevice(_ captureDevice: CaptureDevice) -> AVCaptureVideoPreviewLayer? {
        for connection in connections {
            if let previewLayer = connection.videoPreviewLayer {
                for inputPort in connection.inputPorts where inputPort.mediaType == .video {
                    if inputPort.sourceDevicePosition.captureDevice == captureDevice {
                        return previewLayer
                    }
                }
            }
        }
        return nil
    }
}

private extension AVCaptureVideoPreviewLayer {
    var device: CaptureDevice? {
        guard let connection else {
            return nil
        }
        for inputPort in connection.inputPorts where inputPort.mediaType == .video {
            return inputPort.sourceDevicePosition.captureDevice
        }
        return nil
    }
}

private extension AVCaptureOutput {
    var device: CaptureDevice? {
        for connection in connections {
            for inputPort in connection.inputPorts where inputPort.mediaType == .video {
                return inputPort.sourceDevicePosition.captureDevice
            }
        }
        return nil
    }
}

final actor CaptureSessionController {
    private let session: AVCaptureSession

    init() throws {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            throw Error.failed(reason: "MultiCam not supported on this device")
        }

        session = AVCaptureMultiCamSession()
    }

    deinit {
        // NOTE: `NSKeyValueObservation` will invalidate itself when it's `deinit`.
        let session = session
        Task { [session] in
            session.stopRunning()
        }
    }

    func start() throws {
        startObserving()

        // This call takes some amount of time. Calls to this actor may be delayed for a while.
        session.startRunning()
    }

    func stop() throws {
        // This call takes some amount of time. Calls to this actor may be delayed for a while.
        session.stopRunning()

        stopObserving()
    }

    // TODO: Consider to use `AsyncSequence` instead.
    @MainActor
    private let isRunningSubject = PassthroughSubject<Bool, Never>()

    @MainActor
    var isRunningPublisher: AnyPublisher<Bool, Never> {
        isRunningSubject.eraseToAnyPublisher()
    }

    @MainActor
    private var isRunning: Bool = false {
        // Can't use `@Published` due to actor boundary which `@MainActor`
        // is not applied to `projectValue` or `wrappedValue`, somehow.
        didSet {
            guard oldValue != isRunning else {
                return
            }
            isRunningSubject.send(isRunning)
        }
    }

    private nonisolated func setIsRunning(_ isRunning: Bool) {
        Task { @MainActor in
            self.isRunning = isRunning
        }
    }

    private var keyValueObservations: [NSKeyValueObservation] = []

    private func startObserving() {
        guard keyValueObservations.isEmpty else {
            return
        }
        let keyValueObservation = session.observe(\.isRunning, options: .new) { [weak self] _, change in
            guard let self, let isRunning = change.newValue else {
                return
            }
            setIsRunning(isRunning)
        }
        keyValueObservations.append(keyValueObservation)

        // TODO: Observe many other events, includes system notifications.
    }

    private func stopObserving() {
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    // `AVCaptureVideoPreviewLayer` retains `session`.
    private var videoPreviewLayers: [CaptureDevice : AVCaptureVideoPreviewLayer] = [:]

    private var _frontCameraDeviceInput: AVCaptureDeviceInput?

    private var frontCameraDeviceInput: AVCaptureDeviceInput {
        get throws {
            if let frontCameraDeviceInput = _frontCameraDeviceInput {
                return frontCameraDeviceInput
            }

            session.beginConfiguration()
            defer {
                session.commitConfiguration()
            }

            guard let frontCameraDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                throw Error.failed(reason: "Could not find the front camera")
            }

            let frontCameraDeviceInput = try AVCaptureDeviceInput(device: frontCameraDevice)
            guard session.canAddInput(frontCameraDeviceInput) else {
                throw Error.failed(reason: "Could not add front camera device input")
            }
            session.addInputWithNoConnections(frontCameraDeviceInput)

            _frontCameraDeviceInput = frontCameraDeviceInput
            return frontCameraDeviceInput
        }
    }

    private var _backCameraDeviceInput: AVCaptureDeviceInput?

    private var backCameraDeviceInput: AVCaptureDeviceInput {
        get throws {
            if let backCameraDeviceInput = _backCameraDeviceInput {
                return backCameraDeviceInput
            }

            session.beginConfiguration()
            defer {
                session.commitConfiguration()
            }

            guard let backCameraDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ) else {
                throw Error.failed(reason: "Could not find the back camera")
            }

            let backCameraDeviceInput = try AVCaptureDeviceInput(device: backCameraDevice)

            guard session.canAddInput(backCameraDeviceInput) else {
                throw Error.failed(reason: "Could not add back camera device input")
            }
            session.addInputWithNoConnections(backCameraDeviceInput)

            _backCameraDeviceInput = backCameraDeviceInput
            return backCameraDeviceInput
        }
    }

    private var _microphoneDeviceInput: AVCaptureDeviceInput?

    private var microphoneDeviceInput: AVCaptureDeviceInput {
        get throws {
            session.beginConfiguration()
            defer {
                session.commitConfiguration()
            }

            if let microphoneDeviceInput = _microphoneDeviceInput {
                return microphoneDeviceInput
            }

            guard let microphoneDevice = AVCaptureDevice.default(for: .audio) else {
                throw Error.failed(reason: "Could not find the microphone")
            }

            let microphoneDeviceInput = try AVCaptureDeviceInput(device: microphoneDevice)

            guard session.canAddInput(microphoneDeviceInput) else {
                throw Error.failed(reason: "Could not add microphone device input")
            }
            session.addInputWithNoConnections(microphoneDeviceInput)

            _microphoneDeviceInput = microphoneDeviceInput
            return microphoneDeviceInput
        }
    }

    private func videoPort(for device: CaptureDevice) throws -> AVCaptureDeviceInput.Port {
        let cameraDeviceInput = switch device {
        case .frontCamera:
            try frontCameraDeviceInput
        case .backCamera:
            try backCameraDeviceInput
        }

        guard let videoPort = cameraDeviceInput.ports(
            for: .video,
            sourceDeviceType: cameraDeviceInput.device.deviceType,
            sourceDevicePosition: cameraDeviceInput.device.position
        ).first else {
            throw Error.failed(reason: "Could not find the camera device input's video port")
        }

        return videoPort
    }

    private func audioPort(for device: CaptureDevice) throws -> AVCaptureDeviceInput.Port {
        let microphoneDeviceInput = try microphoneDeviceInput

        guard let audioPort = microphoneDeviceInput.ports(
            for: .audio,
            sourceDeviceType: microphoneDeviceInput.device.deviceType,
            sourceDevicePosition: device.position
        ).first else {
            throw Error.failed(reason: "Could not find the camera device input's audio port")
        }

        return audioPort
    }

    func applyConfigurations(_ configurations: [CaptureConfiguration]) throws {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        var usedConnections: [AVCaptureConnection] = []

        for configuration in configurations {
            switch configuration {
            case .videoPreviewLayer(let assignVideoPreviewLayer, device: let device):
                if let layer = videoPreviewLayers[device] {
                    if let connection = layer.connection {
                        usedConnections.append(connection)
                    }
                    Task { @MainActor in
                        assignVideoPreviewLayer.action?(layer)
                    }
                } else {
                    let layer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
                    let videoPort = try videoPort(for: device)
                    let connection = AVCaptureConnection(
                        inputPort: videoPort,
                        videoPreviewLayer: layer
                    )
                    guard session.canAddConnection(connection) else {
                        throw Error.failed(reason: "Could not add a connection to the camera video preview layer")
                    }
                    session.addConnection(connection)
                    usedConnections.append(connection)

                    videoPreviewLayers[device] = layer
                    Task { @MainActor in
                        assignVideoPreviewLayer.action?(layer)
                    }
                }

            case .photoOutput(let output, device: let device):
                if session.outputs.contains(output) {
                    if output.device == device {
                        usedConnections.append(contentsOf: output.connections)
                        continue
                    }

                    for connection in output.connections where connection.output == output {
                        session.removeConnection(connection)
                    }
                } else {
                    guard session.canAddOutput(output) else {
                        throw Error.failed(reason: "Could not add the output")
                    }
                    session.addOutputWithNoConnections(output)
                }

                let videoPort = try videoPort(for: device)
                let connection = AVCaptureConnection(
                    inputPorts: [videoPort],
                    output: output
                )
                // Mirror photo vertically for front camera, as like preview layer
                // which is automatically mirror video.
                if device.position == .front {
                    connection.isVideoMirrored = true
                }
                guard session.canAddConnection(connection) else {
                    throw Error.failed(reason: "Could not add a video connection to the output")
                }
                session.addConnection(connection)
                usedConnections.append(connection)

            case .movieFileOutput(let output, device: let device):
                if session.outputs.contains(output) {
                    if output.device == device {
                        usedConnections.append(contentsOf: output.connections)
                        continue
                    }

                    for connection in output.connections where connection.output == output {
                        session.removeConnection(connection)
                    }
                } else {
                    guard session.canAddOutput(output) else {
                        throw Error.failed(reason: "Could not add the output")
                    }
                    session.addOutputWithNoConnections(output)
                }

                let videoPort = try videoPort(for: device)
                let videoConnection = AVCaptureConnection(
                    inputPorts: [videoPort],
                    output: output
                )
                // Mirror photo vertically for front camera, as like preview layer
                // which is automatically mirror video.
                if device.position == .front {
                    videoConnection.isVideoMirrored = true
                }
                guard session.canAddConnection(videoConnection) else {
                    throw Error.failed(reason: "Could not add a video connection to the output")
                }
                session.addConnection(videoConnection)
                usedConnections.append(videoConnection)

                let audioPort = try audioPort(for: device)
                let audioConnection = AVCaptureConnection(
                    inputPorts: [audioPort],
                    output: output
                )
                guard session.canAddConnection(audioConnection) else {
                    throw Error.failed(reason: "Could not add a audio connection to the output")
                }
                session.addConnection(audioConnection)
                usedConnections.append(audioConnection)
            }
        }

        for connection in session.connections where !usedConnections.contains(usedConnections) {
            if let layer = connection.videoPreviewLayer {
                layer.session = nil
            } else if let output = connection.output {
                session.removeOutput(output)
            }
        }
    }
}
