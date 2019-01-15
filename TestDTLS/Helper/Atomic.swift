//
//  Atomic.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

import Foundation

final class Atomic<A> {
    private var queue = DispatchQueue(label: "Atomic")
    private var _value: A
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        get {
            return queue.sync { self._value }
        }
        set {
            queue.async { self._value = newValue }
        }
    }
}
