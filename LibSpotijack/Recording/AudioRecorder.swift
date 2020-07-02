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

public final class AudioRecorder: NSObject, RecordingEngine {

    // MARK: - Nested Types

    public enum ConfigurationError: Error {
        case noInputDeviceSelected

        case inputDeviceUnavailable(AVCaptureDevice, reason: Error)
        case inputDeviceUnusable(AVCaptureDevice)
        case outputDeviceUnusable
    }

    // MARK: - Public Properties

    var isRecording: Bool {
        sessionOutput.isRecording
    }

    // MARK: - Private Properties

    private let session = AVCaptureSession()
    private let inputDevice: AVCaptureDevice
    private let sessionOutput = AVCaptureAudioFileOutput()
    private let audioSettings: AudioSettings

    // MARK: - Initializers

    public init(inputDevice: AVCaptureDevice, audioSettings: AudioSettings) {
        self.inputDevice = inputDevice
        self.audioSettings = audioSettings
    }

    // MARK: - Public Methods

    public func startNewRecording(using configuration: RecordingConfiguration) throws {
        os_signpost(.begin, log: log, name: "Starting New Recording")
        defer { os_signpost(.end, log: log, name: "Starting New Recording") }

        if !session.isRunning {
            try startCaptureSession()
        }

        os_log(.info, log: log, "AudioRecorder starting a new recording to %@", configuration.fileLocation.absoluteString)
        sessionOutput.startRecording(
            to: configuration.fileLocation,
            outputFileType: audioSettings.container.fileType,
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

        if session.inputs.isEmpty {
            do {
                try configureSessionInputs()
            } catch {
                os_log(.error, log: log, "Failed to configure AudioRecorder capture session inputs with error: %@",
                       String(describing: error))
                throw error
            }
        }

        if session.outputs.isEmpty {
            do {
                try configureSessionOutput()
            } catch {
                os_log(.error, log: log, "Failed to configure AudioRecorder capture session outputs with error: %@",
                       String(describing: error))
                throw error
            }
        }

        session.startRunning()
    }

    private func configureSessionOutput() throws {
        // Important that the output is configured _after_ the input otherwise the output's audio settings will not
        // apply.
        assert(!session.inputs.isEmpty, "AVCaptureSession inputs need to be configured before the output is configured")

        guard session.canAddOutput(sessionOutput) else {
            throw ConfigurationError.outputDeviceUnusable
        }

        session.addOutput(sessionOutput)

        sessionOutput.audioSettings = [
            AVFormatIDKey: audioSettings.encoding.formatID
        ]
    }

    private func configureSessionInputs() throws {
        let captureInput: AVCaptureDeviceInput
        do {
            captureInput = try AVCaptureDeviceInput(device: inputDevice)
        } catch {
            throw ConfigurationError.inputDeviceUnavailable(inputDevice, reason: error)
        }

        guard session.canAddInput(captureInput) else {
            throw ConfigurationError.inputDeviceUnusable(inputDevice)
        }

        session.inputs.forEach(session.removeInput)
        session.addInput(captureInput)
    }
}

extension AudioRecorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            os_log(.error, log: log, "AudioRecorder failed to record to %@ with error %{public}@",
                   outputFileURL.absoluteString, String(describing: error))
        } else {
            os_log(.info, log: log, "AudioRecorder finished recording to %@", outputFileURL.absoluteString)
        }
    }
}
