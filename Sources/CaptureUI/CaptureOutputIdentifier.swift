//
//  CaptureOutputIdentifier.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation

// This implementation is basically `any Hashable` type erasure.

struct CaptureOutputIdentifier: Hashable {
    static func == (
        lhs: CaptureOutputIdentifier,
        rhs: CaptureOutputIdentifier
    ) -> Bool {
        lhs.isEqual(rhs)
    }

    private var value: Any
    private var isEqual: (_ to: CaptureOutputIdentifier) -> Bool
    private var hash: (_ hasher: inout Hasher) -> Void

    func hash(into hasher: inout Hasher) {
        hash(&hasher)
    }

    init<Value>(_ value: Value) where Value: Hashable {
        self.value = value
        isEqual = { rhs in
            guard let rhsValue = rhs.value as? Value else {
                return false
            }
            return rhsValue == value
        }
        hash = { hasher in
            value.hash(into: &hasher)
        }
    }
}
