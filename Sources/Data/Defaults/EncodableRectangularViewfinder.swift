/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct EncodableRectangularViewfinder: DefaultsEncodable {
    private let viewfinder: RectangularViewfinder

    init(viewfinder: RectangularViewfinder) {
        self.viewfinder = viewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "size": viewfinder.sizeWithUnitAndAspect.jsonString,
            "color": viewfinder.color.sdcHexString,
            "style": viewfinder.style.jsonString,
            "lineStyle": viewfinder.lineStyle.jsonString,
            "dimming": viewfinder.dimming,
            "animation": viewfinder.animation?.jsonString,
            "disabledDimming": viewfinder.disabledDimming,
            "disabledColor": viewfinder.disabledColor.sdcHexString
        ]
    }
}
