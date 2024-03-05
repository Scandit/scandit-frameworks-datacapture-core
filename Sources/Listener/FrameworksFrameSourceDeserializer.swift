/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public class FrameworksFrameSourceDeserializer: NSObject {
    private let frameSourceListener: FrameSourceListener
    private let torchListener: TorchListener

    public init(frameSourceListener: FrameSourceListener, torchListener: TorchListener) {
        self.frameSourceListener = frameSourceListener
        self.torchListener = torchListener
    }

    var camera: Camera? {
        willSet {
            camera?.removeListener(frameSourceListener)
            camera?.removeTorchListener(torchListener)
        }
        didSet {
            camera?.addListener(frameSourceListener)
            camera?.addTorchListener(torchListener)
        }
    }

    private var imageFrameSource: ImageFrameSource? {
        willSet {
            imageFrameSource?.removeListener(frameSourceListener)
        }
        didSet {
            imageFrameSource?.addListener(frameSourceListener)
        }
    }

    public func releaseCurrentCamera() {
        camera = nil
        imageFrameSource = nil
    }
}

extension FrameworksFrameSourceDeserializer: FrameSourceDeserializerDelegate {
    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingFrameSource frameSource: FrameSource,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingFrameSource frameSource: FrameSource,
                                        from jsonValue: JSONValue) {
        camera = frameSource as? Camera
        if let camera = camera {
            if jsonValue.containsKey("desiredTorchState") {
                var torchState: TorchState = .off
                SDCTorchStateFromJSONString(jsonValue.string(forKey: "desiredTorchState"), &torchState)
                camera.desiredTorchState = torchState
            }
            if jsonValue.containsKey("desiredState") {
                var desiredState: FrameSourceState = .off
                SDCFrameSourceStateFromJSONString(jsonValue.string(forKey: "desiredState"), &desiredState)
                camera.switch(toDesiredState: desiredState)
            }
            self.camera = camera
        } else {
            guard let imageFrameSource = frameSource as? ImageFrameSource else {
            	return
            }
            if jsonValue.containsKey("desiredState") {
                let desiredStateJson = jsonValue.string(forKey: "desiredState")
                var desiredState = FrameSourceState.on
                if SDCFrameSourceStateFromJSONString(desiredStateJson, &desiredState) {
                    imageFrameSource.switch(toDesiredState: desiredState)
                }
            }
            self.imageFrameSource = imageFrameSource
        }
    }

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didStartDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}

    public func frameSourceDeserializer(_ deserializer: FrameSourceDeserializer,
                                 didFinishDeserializingCameraSettings settings: CameraSettings,
                                 from jsonValue: JSONValue) {}
}
