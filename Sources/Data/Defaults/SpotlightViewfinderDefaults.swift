/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

struct SpotlightViewfinderDefaults: DefaultsEncodable {
    let viewfinder: SpotlightViewfinder

    func toEncodable() -> [String: Any?] {
        [
            "size": viewfinder.sizeWithUnitAndAspect.jsonString,
            "enabledBorderColor": viewfinder.enabledBorderColor.sdcHexString,
            "disabledBorderColor": viewfinder.disabledBorderColor.sdcHexString,
            "backgroundColor": viewfinder.backgroundColor.sdcHexString
        ]
    }
}
