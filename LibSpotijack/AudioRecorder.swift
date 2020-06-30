//
//  AudioRecorder.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 30/06/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "AudioRecorder")

public final class AudioRecorder: NSObject {

    // MARK: - Nested Types

    public enum ConfigurationError: Error {
        case noInputDeviceSelected

        case inputDeviceUnavailable(AVCaptureDevice, reason: Error)
        case inputDeviceUnusable(AVCaptureDevice)
        case outputDeviceUnusable
    }

    // MARK: - Properties

    private let session = AVCaptureSession()
    private var inputDevice: AVCaptureDevice?
    private let sessionOutput = AVCaptureAudioFileOutput()

    private var hasConfiguredSession: Bool {
        !session.inputs.isEmpty && !session.outputs.isEmpty
    }

    // MARK: - Public Methods

    public func setInputDevice(_ device: AVCaptureDevice) throws {
        do {
            os_log(.info, log: log, "Setting AudioRecorder input device to %@", device.description)

            if hasConfiguredSession {
                os_log(.info, log: log, "AudioRecorder session requires reconfiguring")
                try reconfigureSession(for: device)
            }

            inputDevice = device

        } catch {
            os_log(.error, log: log, "Failed to changed input device of AudioRecorder because %{public}@",
                   String(describing: error))
            throw error
        }
    }

    public func startNewRecording(using configuration: Configuration) throws {
        os_log(.info, log: log, "AudioRecorder starting a new recording")

        os_signpost(.begin, log: log, name: "Starting New Recording")
        defer { os_signpost(.end, log: log, name: "Starting New Recording") }

        sessionOutput.audioSettings = [
            AVFormatIDKey: configuration.encoding.formatID
        ]

        if !session.isRunning {
            try startCaptureSession()
        }

        sessionOutput.startRecording(
            to: configuration.outputFile,
            outputFileType: configuration.fileFormat.fileType,
            recordingDelegate: self
        )
    }

    public func stopRecording() {
        os_log(.info, log: log, "AudioRecorder is ending recording")
        os_signpost(.begin, log: log, name: "Stopping Recording")
        defer { os_signpost(.end, log: log, name: "Stopping Recording") }

        sessionOutput.stopRecording()
        session.stopRunning()

    }

    // MARK: - Private Methods

    private func startCaptureSession() throws {
        os_log(.info, log: log, "Starting AudioRecorder capture session")

        os_signpost(.begin, log: log, name: "Start Capture Session")
        defer { os_signpost(.end, log: log, name: "Start Capture Session") }

        if !hasConfiguredSession {
            do {
                try configureCaptureSession()
            } catch {
                os_log(.error, log: log, "Failed to configure AudioRecorder capture session with error: %@",
                       String(describing: error))
                throw error
            }
        }

        session.startRunning()
    }

    private func configureCaptureSession() throws {
        guard let inputDevice = self.inputDevice else {
            throw ConfigurationError.noInputDeviceSelected
        }

        let captureInput: AVCaptureDeviceInput
        do {
            captureInput = try AVCaptureDeviceInput(device: inputDevice)
        } catch {
            throw ConfigurationError.inputDeviceUnavailable(inputDevice, reason: error)
        }

        guard session.canAddInput(captureInput) else {
            throw ConfigurationError.inputDeviceUnusable(inputDevice)
        }

        guard session.canAddOutput(sessionOutput) else {
            throw ConfigurationError.outputDeviceUnusable
        }

        session.addInput(captureInput)
        session.addOutput(sessionOutput)
    }

    private func reconfigureSession(for inputDevice: AVCaptureDevice) throws {
        assert(hasConfiguredSession, "Attempt to reconfigure a session that has not been configured")
        assert(!session.isRunning, "Attempt to reconfigure a session that is already running")

        let captureInput: AVCaptureDeviceInput
        do {
            captureInput = try AVCaptureDeviceInput(device: inputDevice)
        } catch {
            throw ConfigurationError.inputDeviceUnavailable(inputDevice, reason: error)
        }

        guard session.canAddInput(captureInput) else {
            throw ConfigurationError.inputDeviceUnusable(inputDevice)
        }

        session.inputs.forEach(session.removeInput(_:))
        session.addInput(captureInput)
    }
}

extension AudioRecorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    }
}
