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
import os.lock

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "AudioRecorder")

final class AudioRecorder: NSObject, RecordingEngine {

    // MARK: - Nested Types

    enum ConfigurationError: Error {
        case noInputDeviceSelected
        case inputDeviceUnavailable(AVCaptureDevice, reason: Error)
        case inputDeviceUnusable(AVCaptureDevice)
        case outputDeviceUnusable
    }

    private enum RecordingCommand {
        case none
        case startNewRecording(RecordingConfiguration)
        case endRecording
    }

    // MARK: - Properties

    weak var delegate: RecordingEngineDelegate?

    // MARK: - Private Properties

    private let session = AVCaptureSession()
    private let inputDevice: AVCaptureDevice
    private let sessionOutput = AVCaptureAudioFileOutput()
    private let audioSettings: AudioSettings

    /// A serial queue to configure the capture session on.
    private let sessionQueue = DispatchQueue(label: "org.alexj.Spotijack.AudioRecorderQueue")

    /// Tracks the files being written to in the background by `sessionOutput`.
    private let recordingGroup = DispatchGroup()

    /// A command the recorder should carry out when it's outputted the next sample buffer. The command is
    /// reset after each sample.
    private var nextRecordingCommand: RecordingCommand = .none
    private let commandLock = OSUnfairLock()

    // MARK: - Initializers

    init(inputDevice: AVCaptureDevice, audioSettings: AudioSettings) {
        self.inputDevice = inputDevice
        self.audioSettings = audioSettings
    }

    convenience init(convertibleDevice: AVCaptureDeviceConvertible, audioSettings: AudioSettings) {
        self.init(inputDevice: convertibleDevice.resolvedDevice, audioSettings: audioSettings)
    }

    // MARK: - Methods

    func prepareToRecord(_ completion: @escaping (Result<Void, Error>) -> Void) {
        os_log(.info, log: log, "AudioRecorder is preparing to record")

        sessionQueue.async {
            let configResult = Result { try self.recordingQueue_configureCaptureSession() }

            if case .success = configResult {
                os_log(.info, log: log, "AudioRecorder is ready to record")
            }

            DispatchQueue.main.async { completion(configResult) }
        }
    }

    func startNewRecording(using configuration: RecordingConfiguration) throws {
        assert(sessionQueue.sync { session.isRunning }, "Attempt to start a new recording without preparing the session")

        commandLock.withCriticalScope {
            if case .none = nextRecordingCommand {
                nextRecordingCommand = .startNewRecording(configuration)
            }
        }
    }

    func stopRecording(completionHandler: (() -> Void)?) {
        os_log(.info, log: log, "AudioRecorder asked to end recording")

        // If a recording is in progress it'll be stopped when the next sample is produced.
        commandLock.withCriticalScope {
            nextRecordingCommand = .endRecording
        }

        // When the session output stops recording, it continues to write data in the background. The session can't be
        // stopped until this finishes otherwise data will be lost so we block the session configuration queue until the
        // output finishes writing all of its files.
        sessionQueue.async { [weak self] in
            self?.recordingGroup.wait()
            self?.session.stopRunning()

            self?.commandLock.withCriticalScope {
                self?.nextRecordingCommand = .none
            }

            DispatchQueue.main.async {
                completionHandler?()
            }

            os_log(.info, log: log, "AudioRecorder has finished all recording activity")
        }
    }

    // MARK: - Queue Specific Methods

    private func recordingQueue_configureCaptureSession() throws {
        dispatchPrecondition(condition: .onQueue(sessionQueue))

        guard !session.isRunning else {
            return
        }

        os_signpost(.begin, log: log, name: "Configuring Capture Session")
        defer { os_signpost(.end, log: log, name: "Configuring Capture Session") }

        do {
            session.beginConfiguration()

            if session.inputs.isEmpty {
                try configureSessionInputs()
            }

            if session.outputs.isEmpty {
                try configureSessionOutput()
            }

            session.commitConfiguration()
            session.startRunning()
        } catch {
            os_log(.error, log: log, "Failed to configure capture session with error %{public}s",
                   String(describing: error))
            session.commitConfiguration()
            throw error
        }
    }

    private func configureSessionOutput() throws {
        // Important that the output is configured _after_ the input otherwise the output's audio settings will not
        // apply.
        assert(!session.inputs.isEmpty, "AVCaptureSession inputs need to be configured before the output is configured")

        guard session.canAddOutput(sessionOutput) else {
            throw ConfigurationError.outputDeviceUnusable
        }

        sessionOutput.delegate = self
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

extension AudioRecorder: AVCaptureFileOutputDelegate {
    func fileOutputShouldProvideSampleAccurateRecordingStart(_ output: AVCaptureFileOutput) -> Bool {
        return true
    }

    func fileOutput(_ output: AVCaptureFileOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        commandLock.withCriticalScope {
            switch nextRecordingCommand {
            case .none:
                break

            case .startNewRecording(let config):
                recordingGroup.enter()
                sessionOutput.startRecording(
                    to: config.fileLocation,
                    outputFileType: audioSettings.container.fileType,
                    recordingDelegate: self
                )

            case .endRecording:
                sessionOutput.stopRecording()
                nextRecordingCommand = .none
            }

            nextRecordingCommand = .none
        }
    }
}

extension AudioRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer { recordingGroup.leave() }

        if let error = error {
            os_log(.error, log: log, "AudioRecorder failed to record to %s with error %{public}s",
                   outputFileURL.path, String(describing: error))
        } else {
            os_log(.info, log: log, "AudioRecorder finished recording to %s", outputFileURL.path)
        }

        delegate?.recordingEngine(self, didFinishRecordingTo: outputFileURL, withError: error)
    }
}
