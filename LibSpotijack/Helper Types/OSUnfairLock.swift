//
//  OSSpinLock.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 25/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import os.lock

final class OSUnfairLock: NSLocking {

    private var _lock = os_unfair_lock()

    func lock() {
        os_unfair_lock_lock(&_lock)
    }

    func unlock() {
        os_unfair_lock_unlock(&_lock)
    }
}

extension NSLocking {
    func withCriticalScope<T>(_ work: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try work()
    }
}
