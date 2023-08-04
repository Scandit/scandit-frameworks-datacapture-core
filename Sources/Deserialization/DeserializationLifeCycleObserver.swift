/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore

@objc
public protocol DeserializationLifeCycleObserver: NSObjectProtocol {
    @objc optional func parsersRemoved()
    @objc optional func didDisposeDataCaptureContext()
    @objc optional func dataCaptureContext(deserialized context: DataCaptureContext?)
    @objc optional func dataCaptureView(deserialized view: DataCaptureView?)
}

public final class DeserializationLifeCycleDispatcher {
    public static let shared = DeserializationLifeCycleDispatcher()

    private init() {}

    private var observers = NSMutableSet()

    public func attach(observer: DeserializationLifeCycleObserver) {
        observers.add(observer)
    }

    public func detach(observer: DeserializationLifeCycleObserver) {
        observers.remove(observer)
    }

    func dispatchParsersRemoved() {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.parsersRemoved)) {
                $0.parsersRemoved!()
            }
        }
    }

    func dispatchDataCaptureContextDeserialized(context: DataCaptureContext?) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureContext(deserialized:))) {
                $0.dataCaptureContext!(deserialized: context)
            }
        }
    }

    func dispatchDataCaptureViewDeserialized(view: DataCaptureView?) {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.dataCaptureView(deserialized:))) {
                $0.dataCaptureView!(deserialized: view)
            }
        }
    }

    func dispatchDataCaptureContextDisposed() {
        observers.compactMap { $0 as? DeserializationLifeCycleObserver }.forEach {
            if $0.responds(to: #selector(DeserializationLifeCycleObserver.didDisposeDataCaptureContext)) {
                $0.didDisposeDataCaptureContext!()
            }
        }
    }
}
