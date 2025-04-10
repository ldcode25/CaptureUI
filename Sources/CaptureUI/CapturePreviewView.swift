//
//  CapturePreviewView.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import AVFoundation
import Foundation
import SwiftUI

private final class CapturePreviewUIView: UIView {
    // Always first sublayer should be the video preview layer.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        get {
            layer.sublayers?.first as? AVCaptureVideoPreviewLayer
        }
        set {
            layer.sublayers?.first?.removeFromSuperlayer()
            if let newValue {
                newValue.videoGravity = .resizeAspectFill
                layer.addSublayer(newValue)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let videoPreviewLayer {
            videoPreviewLayer.frame = layer.bounds
        }
    }
}

private struct CapturePreviewUIViewRepresentable: UIViewRepresentable {
    var assignVideoPlayerLayer: CaptureConfiguration.AssignVideoPlayerLayer

    func makeUIView(context: Context) -> CapturePreviewUIView {
        let uiView = CapturePreviewUIView()
        assignVideoPlayerLayer.action = { videoPreviewLayer in
            uiView.videoPreviewLayer = videoPreviewLayer
        }
        return uiView
    }

    func updateUIView(_ uiView: CapturePreviewUIView, context: Context) {
    }
}

public struct CapturePreviewView: View {
    @State
    private var assignVideoPlayerLayer: InitializeOnce<CaptureConfiguration.AssignVideoPlayerLayer>

    var device: CaptureDevice

    public init(device: CaptureDevice) {
        self.device = device
        assignVideoPlayerLayer = .init(CaptureConfiguration.AssignVideoPlayerLayer())
    }

    private var captureConfigurations: [CaptureConfiguration] {
        [.videoPreviewLayer(assignVideoPlayerLayer.value, device: device)]
    }

    public var body: some View {
        CapturePreviewUIViewRepresentable(assignVideoPlayerLayer: assignVideoPlayerLayer.value)
#if targetEnvironment(simulator)
            .overlay {
                CaptureSimulatorPreviewOverlayView(device: device)
            }
#endif
            .preference(key: CaptureConfiguration.Key.self, value: captureConfigurations)
    }
}
