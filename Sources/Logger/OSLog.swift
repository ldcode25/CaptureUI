//
//  OSLog.swift
//  Logger
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation
import OSLog

private extension LogType {
    var osLogType: OSLogType {
        switch self {
        case .default:
            .default
        case .info:
            .info
        case .debug:
            .debug
        case .error:
            .error
        case .fault:
            .fault
        }
    }
}

extension LogSink {
    public static var osLog: Self {
        .init(
            log: { type, file, line, function, message in
                if let message = message() {
                    os_log("%{public}@:%d in %{public}@: %{public}@",
                           type: type.osLogType,
                           NSString(stringLiteral: file).lastPathComponent,
                           line, String(describing: function),
                           message)
                } else {
                    os_log("%{public}@:%d in %{public}@",
                           type: type.osLogType,
                           NSString(stringLiteral: file).lastPathComponent,
                           line,
                           String(describing: function))
                }
            }
        )
    }
}
