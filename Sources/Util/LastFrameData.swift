/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

public final class LastFrameData {
    public static let shared = LastFrameData()

    private init() {}

    private var _frameData: FrameData?

    public var frameData: FrameData? {
        get {
            queue.sync {
                _frameData
            }
        }
        set {
            queue.async(flags: .barrier) {
                self._frameData = newValue
            }
        }
    }

    private var queue = DispatchQueue(label: "com.scandit.frameworks.lastframedata-queue",
                                      attributes: .concurrent)

    public func getLastFrameDataJSON(result: @escaping (String?) -> Void) {
        result(queue.sync {
            frameData?.jsonString
        })
    }
}
