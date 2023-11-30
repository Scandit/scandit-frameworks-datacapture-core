/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditCaptureCore

public enum ScanditFrameworksCoreError: Error, CustomNSError {
    case nilDataCaptureView
    case nilDataCaptureContext
    case deserializationError(error: Error?, json: String?)
    case cameraNotReadyError
    case wrongCameraPosition
    case nilSelf

    public static var errorDomain: String = "SDCFrameworksErrorDomain"

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }

    public var errorCode: Int {
        switch self {
        case .nilDataCaptureView:
            return 1
        case .nilDataCaptureContext:
            return 2
        case .deserializationError:
            return 3
        case .cameraNotReadyError:
            return 4
        case .wrongCameraPosition:
            return 5
        case .nilSelf:
            return 6
        }
    }

    private var localizedDescription: String {
        switch self {
        case .nilDataCaptureView:
            return "The data capture view is nil."
        case .nilDataCaptureContext:
            return "The data capture context is nil."
        case .deserializationError(let error, let json):
            var message: String
            if let error = error {
                message = "An internal deserialization error happened:\n\(error.localizedDescription)"
            } else {
                message = "Unable to deserialize the following JSON:\n\(json!)"
            }
            return message
        case .cameraNotReadyError:
            return "No camera was deserialized yet or it was disposed."
        case .wrongCameraPosition:
            return "The given camera position doesn't match with the current camera's position."
        case .nilSelf:
            return "The current object got deallocated."
        }
    }
}

public class CoreModule: NSObject, FrameworkModule {
    private let frameSourceDeserializer: FrameworksFrameSourceDeserializer
    private let frameSourceListener: FrameworksFrameSourceListener
    private let dataCaptureContextListener: FrameworksDataCaptureContextListener
    private let dataCaptureViewListener: FrameworksDataCaptureViewListener
    private let contextLock = DispatchSemaphore(value: 1)

    public init(frameSourceDeserializer: FrameworksFrameSourceDeserializer,
                frameSourceListener: FrameworksFrameSourceListener,
                dataCaptureContextListener: FrameworksDataCaptureContextListener,
                dataCaptureViewListener: FrameworksDataCaptureViewListener) {
        self.frameSourceDeserializer = frameSourceDeserializer
        self.frameSourceListener = frameSourceListener
        self.dataCaptureContextListener = dataCaptureContextListener
        self.dataCaptureViewListener = dataCaptureViewListener
    }

    var dataCaptureContext: DataCaptureContext? {
        willSet {
            dataCaptureContext?.removeListener(dataCaptureContextListener)
        }
        didSet {
            dataCaptureContext?.addListener(dataCaptureContextListener)
            if let dataCaptureContext = dataCaptureContext {
                DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureContextDeserialized(context: dataCaptureContext)
            }
        }
    }

    public var dataCaptureView: DataCaptureView? {
        willSet {
            dataCaptureView?.removeListener(dataCaptureViewListener)
        }
        didSet {
            dataCaptureView?.addListener(dataCaptureViewListener)
            DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureViewDeserialized(view: dataCaptureView)
        }
    }

    private lazy var deserializers: Deserializers = {
        Deserializers.Factory.create(frameSourceDeserializerDelegate: frameSourceDeserializer)
    }()

    public let defaults: DefaultsEncodable = CoreDefaults.shared

    public func createContextFromJSON(_ json: String, result: FrameworksResult) {
        let block: () -> Void = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            if (self.dataCaptureContext != nil) {
                self.disposeContext()
            }

            do {
                self.contextLock.wait()
                defer { self.contextLock.signal() }

                let deserializerResult = try self.deserializers.dataCaptureContextDeserializer.context(fromJSONString: json)
                self.dataCaptureContext = deserializerResult.context
                self.dataCaptureView = deserializerResult.view
                result.success(result: nil)
            } catch {
                Log.error("Error occurred: \n")
                Log.error(error)
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
            }
        }
        dispatchMain(block)
    }

    public func updateContextFromJSON(_ json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let dataCaptureContext = self.dataCaptureContext else {
                self.createContextFromJSON(json, result: result)
                return
            }
            DeserializationLifeCycleDispatcher.shared.dispatchParsersRemoved()
            do {
                self.contextLock.wait()
                defer { self.contextLock.signal() }

                let updateResult = try self.deserializers.dataCaptureContextDeserializer.update(dataCaptureContext,
                                                                                                view: self.dataCaptureView,
                                                                                                components: [],
                                                                                                fromJSON: json)
                self.dataCaptureView = updateResult.view
                result.success(result: nil)
            } catch {
                Log.error("Error occurred: \n")
                Log.error(error)
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
            }
        }
        dispatchMain(block)
    }

    public func emitFeedback(json: String, result: FrameworksResult) {
        do {
            let feedback = try Feedback(fromJSONString: json)
            feedback.emit()

            dispatchMain {
                result.success(result: nil)
            }
        } catch {
            Log.error("Error occurred: \n")
            Log.error(error)
            result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error, json: nil))
        }
    }

    public func viewPointForFramePoint(json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let dataCaptureView = self.dataCaptureView else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            guard let point = CGPoint(json: json) else {
                Log.error(ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                return
            }
            let viewPoint = dataCaptureView.viewPoint(forFramePoint: point)
            result.success(result: viewPoint.jsonString)
        }
        dispatchMain(block)
    }

    public func viewQuadrilateralForFrameQuadrilateral(json: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                Log.error("Self was nil while trying to create the context.")
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let dataCaptureView = self.dataCaptureView else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureView)
                return
            }
            var quadrilateral = Quadrilateral()
            guard SDCQuadrilateralFromJSONString(json, &quadrilateral) else {
                Log.error(ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil, json: json))
                return
            }
            let viewQuad = dataCaptureView.viewQuadrilateral(forFrameQuadrilateral: quadrilateral)
            result.success(result: viewQuad.jsonString)
        }
        dispatchMain(block)
    }

    public func getCameraState(cameraPosition: String, result: FrameworksResult) {
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)
        guard let camera = frameSourceDeserializer.camera, camera.position == position else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        result.success(result: camera.position.jsonString)
    }

    public func isTorchAvailable(cameraPosition: String, result: FrameworksResult) {
        guard let camera = frameSourceDeserializer.camera else {
            Log.error(ScanditFrameworksCoreError.cameraNotReadyError)
            result.reject(error: ScanditFrameworksCoreError.cameraNotReadyError)
            return
        }
        var position = CameraPosition.unspecified
        SDCCameraPositionFromJSONString(cameraPosition, &position)
        guard camera.position == position else {
            Log.error(ScanditFrameworksCoreError.wrongCameraPosition)
            result.reject(error: ScanditFrameworksCoreError.wrongCameraPosition)
            return
        }
        result.success(result: camera.isTorchAvailable)
    }

    public func disposeContext() {
        self.contextLock.wait()
        defer { self.contextLock.signal() }

        dataCaptureContext?.dispose()
        dataCaptureContext = nil
        frameSourceDeserializer.releaseCurrentCamera()
        LastFrameData.shared.frameData = nil
        DeserializationLifeCycleDispatcher.shared.dispatchDataCaptureContextDisposed()
    }

    public func didStart() {}

    public func didStop() {
        Deserializers.Factory.clearDeserializers()
    }

    public func registerDataCaptureContextListener() {
        dataCaptureContextListener.enable()
    }

    public func unregisterDataCaptureContextListener() {
        dataCaptureContextListener.disable()
    }

    public func registerDataCaptureViewListener() {
        dataCaptureViewListener.enable()
    }

    public func unregisterDataCaptureViewListener() {
        dataCaptureViewListener.disable()
    }

    public func registerFrameSourceListener() {
        frameSourceListener.enable()
    }

    public func unregisterFrameSourceListener() {
        frameSourceListener.disable()
    }
}
