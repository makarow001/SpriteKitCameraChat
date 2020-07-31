//
//  CameraModel.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/26/20.
//  Copyright © 2020 ND. All rights reserved.
//

//
//  CameraModel.swift
//  Practice
//
//  Created by Nikita Dyachkov on 5/30/19.
//  Copyright © 2019 Nikita Dyachkov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CallKit

enum CameraModelError: Error {
    case noPermissionsGranted
    case notInitialized
    case alreadyInitialized
    case noCaptureDeviceFound
    case configCaptureDeviceError
    case capturingNotRunning
}

enum CameraModelState {
    case notInitialized
    case initializing
    case initialized
    case configured
    case error(CameraModelError)
}

protocol CameraModelDelegate: NSObjectProtocol {
    func didUpdated(videoBuffer: CMSampleBuffer)
    func permissions(granted: Bool)
}

protocol CameraModelProtocol: class {
    var state: CameraModelState { get }
    var orientation: AVCaptureVideoOrientation { get set }
    var permissinsGranted: Bool { get }
    var delegate: CameraModelDelegate? { get set }
    func startCapturing() throws
    func suspendCapturing() throws
    func resumeCapturing() throws
    func stopCapturing()
}


final class CameraModel: NSObject, CameraModelProtocol {
    
    weak var delegate: CameraModelDelegate? = nil
    
    var permissinsGranted = false {
        didSet {
            delegate?.permissions(granted: permissinsGranted)
            if permissinsGranted {
                try? startCapturing()
            }
        }
    }
    
    override init() {
        state = .notInitialized
        super.init()
        requestDevicePermissions()
    }
    
    private func requestDevicePermissions() {
        guard case CameraModelState.notInitialized = state else {
            print("Camera is already initialized")
            return
        }
        state = .initializing
        
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
            guard let self = self else { return }
            if granted {
                self.state = .initialized
            }
            self.permissinsGranted = granted
        }
    }
    
    static var fps: Int32 {
        return 30
    }
    
    var orientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait {
        didSet {
            updateVideoOrientation()
        }
    }
    
    var state: CameraModelState = .notInitialized
    
    private(set) var isCaptureVideoAvailable = false
    
    private var isReConfiguring = false
    
    var shouldMirrorCamera = true {
        didSet {
//            applyCameraMirroring()
        }
    }
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    
    private var isRunning = false
    
    public private(set) lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = session.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) ? .hd1280x720 : .inputPriority
        
        return session
    }()
    
    private lazy var videoQueue: DispatchQueue = {
        return DispatchQueue(label: "SpriteKitCameraChat.captureVideo", qos: DispatchQoS.background, target: DispatchQueue.global(qos: DispatchQoS.QoSClass.background))
    }()
    
    func startCapturing() throws {
        if case CameraModelState.notInitialized = state {
            throw CameraModelError.notInitialized
        }
        
        if !permissinsGranted {
            throw CameraModelError.noPermissionsGranted
        }
        
        if case CameraModelState.initialized = state {
            try configureCaptureSession()
        }
        
        if case CameraModelState.configured = state {
            captureSession.startRunning()
            isRunning = true
        }
    }
    
    func suspendCapturing() throws {
        guard case CameraModelState.configured = state, isRunning else {
            throw CameraModelError.capturingNotRunning
        }
        captureSession.stopRunning()
    }
    
    func resumeCapturing() throws {
        guard case CameraModelState.configured = state else {
            throw CameraModelError.capturingNotRunning
        }
        try startCapturing()
    }
    
    func stopCapturing() {
        captureSession.stopRunning()
        isRunning = false
    }
    
    private func configureCaptureSession() throws {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        if let videoDevice = DeviceUtility.videoDevice(withPosition: .front) ?? AVCaptureDevice.default(for: .video) {
            if changeVideoCaptureDevice(videoDevice) {
                addVideoOutput()
                updateVideoOrientation()
                isCaptureVideoAvailable = true
                registerForNotifications()
                state = .configured
                registerForNotifications()
            } else {
                throw CameraModelError.configCaptureDeviceError
            }
        } else {
            print("No video capture device found")
            throw CameraModelError.noCaptureDeviceFound
        }
    }
    
    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(captureSessionRuntimeError(_:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
        notificationCenter.addObserver(self, selector: #selector(captureSessionInterrupted(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(captureSessionInterruptionEnded(_:)), name: .captureSessionInAppCameraInterruptionEnded, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func updateVideoOrientation() {
        if let connection = self.videoDataOutput?.connection(with: .video) {
            captureSession.beginConfiguration()
            if connection.isVideoOrientationSupported {
                print("Setup video orientation")
                connection.videoOrientation = self.orientation
            }
            self.applyCameraMirroring()
            captureSession.commitConfiguration()
        }
    }
    
    private func applyCameraMirroring() {
        if let connection = videoDataOutput?.connection(with: .video) {
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirroringSupported {
                print("Setup video mirroring")
                connection.isVideoMirrored = shouldMirrorCamera
            }
        }
    }
    
    private func changeVideoCaptureDevice(_ device: AVCaptureDevice) -> Bool {
        if let videoInput = videoDeviceInput {
            captureSession.removeInput(videoInput)
        }
        if let deviceInput = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(deviceInput) {
            do {
                try device.lockForConfiguration()

                captureSession.addInput(deviceInput)
                videoDeviceInput = deviceInput

                print("Setup the desired capture frame rate")
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CameraModel.fps)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CameraModel.fps)

                device.unlockForConfiguration()
            }
            catch {
                print("Failed to set the desired capture frame rate")
                return false
            }
            return true
        } else {
            print("Error adding video capture device")
        }
        return false
    }
    
    private func addVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)
        ]
        if !captureSession.canAddOutput(videoOutput) {
            print("Could not find output device")
            if let deviceInput = videoDeviceInput {
                captureSession.removeInput(deviceInput)
            }
            videoDeviceInput = nil
            return
        }

        captureSession.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput = videoOutput
    }
    
    private func clearCaptureSessionConfiguration() {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        
        if let videoOutput = videoDataOutput {
            captureSession.removeOutput(videoOutput)
        }
        if let videoInput = videoDeviceInput {
            captureSession.removeInput(videoInput)
        }
    }
    
    private func reconfigureCaptureSession() throws {
        stopCapturing()
        clearCaptureSessionConfiguration()
        try configureCaptureSession()
    }
    
    fileprivate func tryToReconfigureCaptureSession() {
        isRunning = false
        if isCaptureVideoAvailable {
            state = .initialized
        }
        do {
            try reconfigureCaptureSession()
            try startCapturing()
        }
        catch let error {
            print("Capture session recovery error after interruption: \(error)")
        }
    }
    
    @objc func captureSessionInterrupted(_ notification: NSNotification) {
        guard let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? NSNumber,
            reason.intValue == AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient.rawValue,
            UIApplication.shared.applicationState == .active,
            captureSession.isInterrupted,
            isRunning,
            !isReConfiguring else {
                return
        }
        startDelayedReConfigCamera()
    }
    
    @objc func captureSessionInterruptionEnded(_ notification: NSNotification) {
        guard UIApplication.shared.applicationState == .active,
            captureSession.isInterrupted,
            isRunning,
            !isReConfiguring else {
                return
        }
        startDelayedReConfigCamera()
    }
    
    @objc func captureSessionRuntimeError(_ notification: NSNotification) {
        if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError {
            print("AVFoundation error: \(error)")
        }
        guard UIApplication.shared.applicationState == .active,
            isRunning,
            !isReConfiguring else {
                return
        }
        startDelayedReConfigCamera()
    }
    
    @objc func appDidBecomeActive(_ notification: NSNotification) {
        guard permissinsGranted,
            captureSession.isInterrupted,
            isRunning,
            !isReConfiguring else {
                return
        }
        startDelayedReConfigCamera()
    }
    
    private func startDelayedReConfigCamera() {
        guard !isReConfiguring else { return }
        isReConfiguring = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [unowned self] in
            if self.isRunning {
                print("Camera Re-configuration Started")
                self.tryToReconfigureCaptureSession()
            } else {
                self.isReConfiguring = false
            }
        }
    }
    
    deinit {
        print("CameraModel deinit")
        stopCapturing()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.didUpdated(videoBuffer: sampleBuffer)
    }
}

extension Notification.Name {
    static let captureSessionInAppCameraInterruptionEnded = Notification.Name("captureSessionInAppCameraInterruptionEnded")
}
