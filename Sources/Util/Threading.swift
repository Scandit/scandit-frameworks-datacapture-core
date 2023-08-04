/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation

public func dispatchMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

@discardableResult
public func dispatchMainSync<T>(_ block: () -> T) -> T {
    if Thread.isMainThread {
        return block()
    }
    return dispatchMainSyncUnsafe(block)
}

public func dispatchMainSyncUnsafe<T>(_ block: () -> T) -> T {
    return DispatchQueue.main.sync {
        return block()
    }
}
