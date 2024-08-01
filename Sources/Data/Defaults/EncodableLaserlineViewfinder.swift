/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableLaserlineViewFinder: DefaultsEncodable {
    private let viewfinder: LaserlineViewfinder

    init(viewfinder: LaserlineViewfinder) {
        self.viewfinder = viewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "width": viewfinder.width.jsonString,
            "style": viewfinder.style.jsonString,
            "enabledColor": viewfinder.enabledColor.sdcHexString,
            "disabledColor": viewfinder.disabledColor.sdcHexString
        ]
    }
}
