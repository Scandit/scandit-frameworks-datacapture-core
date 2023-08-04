/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

extension LaserlineViewfinderStyle: CaseIterable {
    public static var allCases: [LaserlineViewfinderStyle] {
        [.legacy, .animated]
    }
}

struct LaserlineViewfinderDefaults: DefaultsEncodable {
    private let defaultViewfinder: LaserlineViewfinder

    init(defaultViewfinder: LaserlineViewfinder) {
        self.defaultViewfinder = defaultViewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "defaultStyle": defaultViewfinder.style.jsonString,
            "styles": Dictionary(uniqueKeysWithValues: LaserlineViewfinderStyle.allCases.map {
                ($0.jsonString, EncodableLaserlineViewFinder(viewfinder: LaserlineViewfinder(style: $0)).toEncodable())
            })
        ]
    }
}

extension RectangularViewfinderStyle: CaseIterable {
    public static var allCases: [RectangularViewfinderStyle] {
        [.legacy, .rounded, .square]
    }
}

struct RectangularViewfinderDefaults: DefaultsEncodable {
    private let defaultViewfinder: RectangularViewfinder

    init(defaultViewfinder: RectangularViewfinder) {
        self.defaultViewfinder = defaultViewfinder
    }

    func toEncodable() -> [String: Any?] {
        [
            "defaultStyle": defaultViewfinder.style.jsonString,
            "styles": Dictionary(uniqueKeysWithValues: RectangularViewfinderStyle.allCases.map {
                ($0.jsonString, EncodableRectangularViewfinder(viewfinder: RectangularViewfinder(style: $0)).toEncodable())
            })
        ]
    }
}

extension CameraPosition: CaseIterable {
    public static var allCases: [CameraPosition] {
        [.worldFacing, .userFacing, .unspecified]
    }
}

struct CoreDefaults: DefaultsEncodable {
    private let cameraDefaults: CameraDefaults
    private let dataCaptureViewDefaults: DataCaptureViewDefaults
    private let laserlineViewfinderDefaults: LaserlineViewfinderDefaults
    private let rectangularViewfinderDefaults: RectangularViewfinderDefaults
    private let aimerViewfinderDefauls: EncodableAimerViewfinder
    private let brushDefaults: EncodableBrush
    private let spotlightViewfinderDefaults: SpotlightViewfinderDefaults

    init(cameraDefaults: CameraDefaults,
         dataCaptureViewDefaults: DataCaptureViewDefaults,
         laserlineViewfinderDefaults: LaserlineViewfinderDefaults,
         rectangularViewfinderDefaults: RectangularViewfinderDefaults,
         aimerViewfinderDefauls: EncodableAimerViewfinder,
         brushDefaults: EncodableBrush,
         spotlightViewfinderDefaults: SpotlightViewfinderDefaults) {
        self.cameraDefaults = cameraDefaults
        self.dataCaptureViewDefaults = dataCaptureViewDefaults
        self.laserlineViewfinderDefaults = laserlineViewfinderDefaults
        self.rectangularViewfinderDefaults = rectangularViewfinderDefaults
        self.aimerViewfinderDefauls = aimerViewfinderDefauls
        self.brushDefaults = brushDefaults
        self.spotlightViewfinderDefaults = spotlightViewfinderDefaults
    }

    func toEncodable() -> [String: Any?] {
        [
            "Version": DataCaptureVersion.version(),
            "deviceID": DataCaptureContext.deviceID,
            "Camera": cameraDefaults.toEncodable(),
            "DataCaptureView": dataCaptureViewDefaults.toEncodable(),
            "LaserlineViewfinder": laserlineViewfinderDefaults.toEncodable(),
            "RectangularViewfinder": rectangularViewfinderDefaults.toEncodable(),
            "AimerViewfinder": aimerViewfinderDefauls.toEncodable(),
            "Brush": brushDefaults.toEncodable(),
            "SpotlightViewfinder": spotlightViewfinderDefaults.toEncodable()
        ]
    }

    static let shared: CoreDefaults = {
        let cameraDefaults = CameraDefaults(cameraSettingsDefaults: EncodableCameraSettings(cameraSettings: CameraSettings()),
                                            defaultPosition: Camera.default?.position,
                                            availablePositions: CameraPosition.allCases.compactMap { Camera(position: $0)?.position })
        let laserlineViewfinderDefaults = LaserlineViewfinderDefaults(defaultViewfinder: LaserlineViewfinder(style: .legacy))
        let rectangularViewfinderDefaults = RectangularViewfinderDefaults(defaultViewfinder: RectangularViewfinder(style: .legacy))
        return CoreDefaults(cameraDefaults: cameraDefaults,
                            dataCaptureViewDefaults: DataCaptureViewDefaults(view: DataCaptureView(frame: .zero)),
                            laserlineViewfinderDefaults: laserlineViewfinderDefaults,
                            rectangularViewfinderDefaults: rectangularViewfinderDefaults,
                            aimerViewfinderDefauls: EncodableAimerViewfinder(viewfinder: AimerViewfinder()),
                            brushDefaults: EncodableBrush(brush: .transparent),
                            spotlightViewfinderDefaults: SpotlightViewfinderDefaults(viewfinder: SpotlightViewfinder()))
    }()
}
