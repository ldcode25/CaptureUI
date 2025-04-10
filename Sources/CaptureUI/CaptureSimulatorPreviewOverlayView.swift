//
//  CaptureSimulatorPreviewOverlayView.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import Foundation
// TODO: Generate video and photo data by the code for simulator.
import SimulatorResources
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

    private var sampleUIImage: UIImage {
        let data = switch device {
        case .frontCamera:
            SimulatorResources.frontPhotoData
        case .backCamera:
            SimulatorResources.backPhotoData
        }
        return UIImage(data: data)!
    }

    var body: some View {
        Image(uiImage: sampleUIImage)
            .resizable()
            .scaledToFill()
            .overlay {
                TimelineView(.animation) { context in
                    Stripes(normalizedStripeOffset: context.date.tick)
                        .foregroundStyle(.white)
                        .background(.black)
                        .opacity(0.5)
                }
            }
    }
}

#Preview {
    CaptureSimulatorPreviewOverlayView()
}
#endif
