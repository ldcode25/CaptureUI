//
//  CaptureOutput.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation
import SwiftUI

final class Box<T>: Equatable {
    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs === rhs
    }

    var value: T

    init(_ value: T) {
        self.value = value
    }
}

public struct CaptureOutput<Content>: View where Content: View {
#if targetEnvironment(simulator)
    @State
    private var controller: InitializeOnce<CaptureSimulatorOutputController>
#else
    @State
    private var controller: InitializeOnce<CaptureOutputController>
#endif

    var device: CaptureDevice
    var content: (CaptureOutputProxy) -> Content

    public init(
        device: CaptureDevice,
        @ViewBuilder content: @escaping (CaptureOutputProxy) -> Content
    ) {
        controller = .init(.init())

        self.device = device
        self.content = content
    }

    private var captureConfigurations: [CaptureConfiguration] {
        controller.value.captureConfigurations(for: device)
    }

    public var body: some View {
        // To reduce configurations both from `content()` and this view,
        // use `background(content:)` with `EmptyView()` instead of `preference(key:value:)` on
        // `content()`, that stops reading `preference(key:value:)` from `content()`.
        VStack {
            content(CaptureOutputProxy(controller: controller.value))
        }
        .background {
            EmptyView()
                .preference(key: CaptureConfiguration.Key.self, value: captureConfigurations)
        }
    }
}
