//
//  CaptureSimulatorSessionController.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#if targetEnvironment(simulator)
import Combine
import Foundation
import Logger

final actor CaptureSimulatorSessionController {
    init() throws {
    }

    func start() throws {
        log(type: .debug, "Start running capture session.")
        Task { @MainActor in
            isRunning = true
        }
    }

    func stop() throws {
        log(type: .debug, "Stop running capture session.")
        Task { @MainActor in
            isRunning = false
        }
    }

    // NOTE: See implementation notes in `CaptureSessionController`.

    @MainActor
    private let isRunningSubject = PassthroughSubject<Bool, Never>()

    @MainActor
    var isRunningPublisher: AnyPublisher<Bool, Never> {
        isRunningSubject.eraseToAnyPublisher()
    }

    @MainActor
    private var isRunning: Bool = false {
        didSet {
            guard oldValue != isRunning else {
                return
            }
            isRunningSubject.send(isRunning)
        }
    }

    func applyConfigurations(_ configurations: [CaptureConfiguration]) throws {
        log(type: .debug, "Apply configurations: \(configurations)")
    }
}
#endif
