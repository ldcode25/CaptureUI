//
//  Logger.swift
//  Logger
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation

public enum LogType: Sendable {
    case `default`
    case info
    case debug
    case error
    case fault
}

public struct LogSink: Sendable {
    public typealias Log = @Sendable (
        _ type: LogType,
        _ file: StaticString,
        _ line: Int,
        _ function: StaticString,
        _ message: @autoclosure @Sendable () -> String?
    ) -> Void

    public var log: Log

    public typealias LogError = @Sendable (
        _ file: StaticString,
        _ line: Int,
        _ function: StaticString,
        _ error: @autoclosure @Sendable () -> any Error
    ) -> Void

    public var logError: LogError

    public init(log: @escaping Log, logError: LogError? = nil) {
        self.log = log

        self.logError = logError ?? { file, line, function, error in
            log(.error, file, line, function, String(describing: error()))
        }
    }
}

extension LogSink {
    public static var null: Self {
        .init(
            log: { _, _, _, _, _ in
            }
        )
    }
}

public final class Logger: @unchecked Sendable {
    static let shared: Logger = .init()

    private let _lock = NSLock()

    private var _sink: LogSink = .null

    private var sink: LogSink {
        get {
            _lock.withLock {
                _sink
            }
        }
        set {
            _lock.withLock {
                _sink = newValue
            }
        }
    }

    public static func use(_ sink: LogSink) {
        shared.sink = sink
    }

    func log(
        type: LogType,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function,
        _ message: @autoclosure @Sendable () -> String? = nil
    ) {
        sink.log(type, file, line, function, message())
    }

    func log(
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function,
        _ error: @autoclosure @Sendable () -> any Error
    ) {
        sink.logError(file, line, function, error())
    }
}

public func log(
    type: LogType = .default,
    file: StaticString = #file,
    line: Int = #line,
    function: StaticString = #function,
    _ message: @autoclosure @Sendable () -> String? = nil
) {
    Logger.shared.log(
        type: type,
        file: file,
        line: line,
        function: function,
        message()
    )
}

public func log(
    file: StaticString = #file,
    line: Int = #line,
    function: StaticString = #function,
    error: @autoclosure @Sendable () -> any Error
) {
    Logger.shared.log(
        file: file,
        line: line,
        function: function,
        error()
    )
}
