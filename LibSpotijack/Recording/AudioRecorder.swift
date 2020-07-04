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

final class AudioRecorder: NSObject, RecordingEngine {

    // MARK: - Nested Types

    enum ConfigurationError: Error {
        case noInputDeviceSelected

        case inputDeviceUnavailable(AVCaptureDevice, reason: Error)
        case inputDeviceUnusable(AVCaptureDevice)
        case outputDeviceUnusable
    }

    // MARK: - Properties

    weak var delegate: RecordingEngineDelegate?

    var isRecording: Bool {
        sessionOutput.isRecording
    }

    // MARK: - Private Properties

    private let session = AVCaptureSession()
    private let inputDevice: AVCaptureDevice
    private let sessionOutput = AVCaptureAudioFileOutput()
    private let audioSettings: AudioSettings

    private let recordingQueue = DispatchQueue(label: "org.alexj.Spotijack.AudioRecorderQueue")
    private let recordingGroup = DispatchGroup()

    // MARK: - Initializers

    init(inputDevice: AVCaptureDevice, audioSettings: AudioSettings) {
        self.inputDevice = inputDevice
        self.audioSettings = audioSettings
    }

    convenience init(convertibleDevice: AVCaptureDeviceConvertible, audioSettings: AudioSettings) {
        self.init(inputDevice: convertibleDevice.resolvedDevice, audioSettings: audioSettings)
    }

    // MARK: - Methods

    func startNewRecording(using configuration: RecordingConfiguration) throws {
        try recordingQueue.sync { try recordingQueue_startNewRecording(using: configuration) }
    }

    func stopRecording() {
        recordingQueue.sync { recordingQueue_stopRecording() }
    }

    // MARK: - Queue Specific Methods

    private func recordingQueue_startNewRecording(using configuration: RecordingConfiguration) throws {
        dispatchPrecondition(condition: .onQueue(recordingQueue))

        os_signpost(.begin, log: log, name: "Starting New Recording")
        defer { os_signpost(.end, log: log, name: "Starting New Recording") }

        if !session.isRunning {
            try startCaptureSession()
        }

        os_log(.info, log: log, "AudioRecorder starting a new recording to %@", configuration.fileLocation.absoluteString)
        recordingGroup.enter()
        sessionOutput.startRecording(
            to: configuration.fileLocation,
            outputFileType: audioSettings.container.fileType,
            recordingDelegate: self
        )
    }

    private func recordingQueue_stopRecording() {
        dispatchPrecondition(condition: .onQueue(recordingQueue))

        os_log(.info, log: log, "AudioRecorder is ending recording")

        os_signpost(.begin, log: log, name: "Stopping Recording")
        defer { os_signpost(.end, log: log, name: "Stopping Recording") }

        sessionOutput.stopRecording()

        // Recording finishes on a background thread. Must wait for it to complete before stopping the capture session.
        // And must block the recording queue so new recordings aren't started until the old session completes.
        recordingQueue.async {
            // Timeout as we can deadlock when calling startNewRecording: and the caller's queue is the queue
            // AVCaptureAudioFileOutput calls the delegate on.
            _ = self.recordingGroup.wait(timeout: .now() + 2)
            self.session.stopRunning()
        }
    }

    // MARK: - Helper Methods

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
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer { recordingGroup.leave() }

        if let error = error {
            os_log(.error, log: log, "AudioRecorder failed to record to %@ with error %{public}@",
                   outputFileURL.absoluteString, String(describing: error))
        } else {
            os_log(.info, log: log, "AudioRecorder finished recording to %@", outputFileURL.absoluteString)
        }

        delegate?.recordingEngine(self, didFinishRecordingTo: outputFileURL, withError: error)
    }
}
