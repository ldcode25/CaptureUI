//
//  InitializeOnce.swift
//  Capture
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import Foundation

// Any `View` stored properties default value and its `init()` is called always
// when the parent view state is changed.
// Therefore any type stored essentially kept `init` again and again, and `@State` keeps only
// the first one and the other ones are immediately `deinit`.
//
// To prevent this behavior, as like what `@StateObject` does, use `@autoclosure` to capture
// initializer and run it once when it's needed.
//
// NOTE: Apple recommend to use `.task()` for initialize once behavior,
// but it is not synchronous at very beginning of view appearance.
// See <https://developer.apple.com/documentation/swiftui/state#Store-observable-objects>

final class InitializeOnce<Value> {
    private let _value: () -> Value

    lazy var value: Value = _value()

    init(_ value: @autoclosure @escaping () -> Value) {
        _value = value
    }
}
