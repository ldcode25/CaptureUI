//
//  CaptureSimulatorPreviewOverlayView.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import Foundation
import SwiftUI

private struct Stripes: View {
    var stripeWidth: CGFloat = 10.0
    var spacing: CGFloat = 10.0
    var angle: Angle = .degrees(45)
    var normalizedStripeOffset: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            let size = max(geometry.size.width, geometry.size.height)
            let stripeSpacing = stripeWidth + spacing
            let numberOfStripes = Int(2 * size / stripeSpacing)
            HStack(spacing: spacing) {
                ForEach(0 ..< numberOfStripes, id: \.self) { _ in
                    Rectangle()
                        .frame(width: stripeWidth, height: 2 * size)
                }
            }
            .offset(x: max(0.0, min(1.0, normalizedStripeOffset)) * stripeSpacing)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .rotationEffect(angle, anchor: .center)
            .offset(x: -size * 0.5, y: -size * 0.5)
        }
        .clipped()
    }
}

private extension Date {
    var tick: CGFloat {
        CGFloat(Int(timeIntervalSince1970 * 10) % 10) / 10
    }
}

struct CaptureSimulatorPreviewOverlayView: View {
    var device: CaptureDevice = .frontCamera

    @State
    private var mockedUIImage: UIImage?

    var body: some View {
        Group {
            if let mockedUIImage {
                Image(uiImage: mockedUIImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }
        }
        .overlay {
            TimelineView(.animation) { context in
                Stripes(normalizedStripeOffset: context.date.tick)
                    .foregroundStyle(.white)
                    .background(.black)
                    .opacity(0.5)
            }
        }
        .onChange(of: device, initial: true) { _, device in
            Task.detached {
                let image = switch device {
                case .frontCamera:
                    SimulatorSupport.shared.frontMockedPhoto
                case .backCamera:
                    SimulatorSupport.shared.backMockedPhoto
                }
                let uiImage = try image.renderUIImage()
                Task { @MainActor in
                    mockedUIImage = uiImage
                }
            }
        }
    }
}

#Preview {
    CaptureSimulatorPreviewOverlayView()
}
#endif
