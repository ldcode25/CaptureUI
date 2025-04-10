//
//  CaptureSession.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation
import Logger
import SwiftUI

public struct CaptureSession<Content, NotSupported>: View where Content: View, NotSupported: View {
#if targetEnvironment(simulator)
    @State
    private var controller: InitializeOnce<CaptureSimulatorSessionController?>
#else
    @State
    private var controller: InitializeOnce<CaptureSessionController?>
#endif

    var isEnabled: Bool

    // This is read-only.
    @Binding
    var isRunning: Bool

    var content: () -> Content
    var notSupported: () -> NotSupported

    public init(
        isEnabled: Bool,
        isRunning: Binding<Bool>? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder notSupported: @escaping () -> NotSupported
    ) {
        controller = .init(try? .init())

        self.isEnabled = isEnabled

        _isRunning = isRunning ?? .constant(false)

        self.content = content
        self.notSupported = notSupported
    }

    public var body: some View {
        if let controller = controller.value {
            // This `VStack` is necessary to have all child view's preference at once, or
            // direct child sibling views calls `onPreferenceChange()` individually.
            VStack {
                content()
            }
            .onPreferenceChange(CaptureConfiguration.Key.self) { configurations in
                let configurations = configurations
                Task {
                    do {
                        try await controller.applyConfigurations(configurations)
                    } catch {
                        log(error: error)
                    }
                }
            }
            .onChange(of: isEnabled, initial: true) { _, isEnabled in
                Task {
                    do {
                        if isEnabled {
                            try await controller.start()
                        } else {
                            try await controller.stop()
                        }
                    } catch {
                        log(error: error)
                    }
                }
            }
            .onReceive(controller.isRunningPublisher) { value in
                isRunning = value
            }
        } else {
            notSupported()
        }
    }
}

extension CaptureSession where NotSupported == EmptyView {
    public init(
        isEnabled: Bool,
        isRunning: Binding<Bool>? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isEnabled: isEnabled,
            isRunning: isRunning,
            content: content,
            notSupported: {
                EmptyView()
            }
        )
    }
}
