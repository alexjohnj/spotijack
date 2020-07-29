//
//  SessionCoordinator.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import Combine
import AVFoundation

import os

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "SessionCoordinator")

public final class SessionCoordinator {

    // MARK: - Nested Types

    typealias RecorderFactory = (AVCaptureDeviceConvertible, AudioSettings) throws -> RecordingEngine

    public enum State {
        case notRecording
        case startingRecording
        case recording

        // The session will move to the `notRecording` state when it has finished writing out recorded audio data.
        case endingRecording

        func canTransition(to otherState: State) -> Bool {
            switch (self, otherState) {
            case (.notRecording, .startingRecording):
                return true

            case (.startingRecording, .recording),
                 (.startingRecording, .endingRecording):
                return true

            case (.recording, .endingRecording):
                return true

            case (.endingRecording, .notRecording):
                return true

            case (.notRecording, _),
                 (.startingRecording, _),
                 (.recording, _),
                 (.endingRecording, _):
                return false
            }
        }
    }

    public struct Configuration: Hashable {
        public var shouldDisableShuffling = true
        public var shouldDisableRepeat = true

        public var fileNameFormatter = FilePathFormatter()
        public var audioSettings = AudioSettings()

        public init(
            shouldDisableShuffling: Bool = true,
            shouldDisableRepeat: Bool = true,
            fileNameFormatter: FilePathFormatter = FilePathFormatter(),
            audioSettings: AudioSettings = AudioSettings()
        ) {
            self.shouldDisableShuffling = shouldDisableShuffling
            self.shouldDisableRepeat = shouldDisableRepeat
            self.fileNameFormatter = fileNameFormatter
            self.audioSettings = audioSettings
        }
    }

    // MARK: - Public Properties

    @Published public private(set) var state: State = .notRecording

    /// The configuration the session applies to new recordings.
    ///
    /// - Warning: It is programmer error to change this when the session is in any state other than `notRecording`.
    ///
    public var configuration: Configuration {
        get {
            withStateLock { _configuration }
        }

        set {
            withStateLock { _configuration = newValue }
        }
    }

    var tempPathGenerator = TemporaryFilePathGenerator.default

    // MARK: - Private Properties

    private let musicApp: MusicApplication
    private let recorderFactory: RecorderFactory
    private let recordingProcessor: RecordingProcessing

    private var stateLock = NSRecursiveLock()

    private var _configuration: Configuration {
        willSet {
            assert(state == .notRecording, "Changing the configuration when the recording session is active is not allowed")
        }
    }
    private var activeRecordingEngine: RecordingEngine?
    private var recordingCancellable: AnyCancellable?
    private var inProgressTracks: [URL: Track] = [:]

    // MARK: - Initializers

    init(
        musicApp: MusicApplication,
        configuration: Configuration = Configuration(),
        recordingProcessor: RecordingProcessing = RecordingProcessor(),
        recorderFactory: @escaping RecorderFactory
    ) {
        self.musicApp = musicApp
        self._configuration = configuration
        self.recordingProcessor = recordingProcessor
        self.recorderFactory = recorderFactory
    }

    public convenience init(musicApp: MusicApplication) {
        self.init(
            musicApp: musicApp,
            recorderFactory: { device, audioSettings in
                return AudioRecorder(convertibleDevice: device, audioSettings: audioSettings)
            }
        )
    }

    // MARK: - Public Methods

    public func startRecording(from captureDevice: AVCaptureDevice) throws {
        try startRecordingFromConvertibleDevice(captureDevice)
    }

    func startRecordingFromConvertibleDevice(_ captureDevice: AVCaptureDeviceConvertible) throws {
        try withStateLock {
            try locked_startRecordingFromConvertibleDevice(captureDevice)
        }
    }

    public func stopRecording() {
        withStateLock {
            locked_stopRecording()
        }
    }

    // MARK: - Private Methods

    private func locked_startRecordingFromConvertibleDevice(_ captureDevice: AVCaptureDeviceConvertible) throws {
        guard state.canTransition(to: .startingRecording),
              let currentTrack = musicApp.currentTrack else {
            return
        }

        state = .startingRecording
        os_log(.info, log: log, "Recording Session is starting.")

        let activeSessionConfiguration = _configuration // Copy the current configuration for the duration of the session
        let recordingEngine = try recorderFactory(captureDevice, activeSessionConfiguration.audioSettings)
        recordingEngine.delegate = self
        activeRecordingEngine = recordingEngine

        musicApp.pause()
        musicApp.playerPosition = 0
        applyMusicAppConfiguration(activeSessionConfiguration)

        recordingEngine.prepareToRecord { [weak self] result in
            switch result {
            case .failure:
                self?.stopRecording()

            case .success:
                self?.didPrepareRecordingEngine(recordingEngine, toRecordTrack: currentTrack)
            }
        }
    }

    private func didPrepareRecordingEngine(_ recordingEngine: RecordingEngine, toRecordTrack track: Track) {
        guard state.canTransition(to: .recording) else { return }

        recordingCancellable = musicApp.trackIDPublisher
            .removeDuplicates()
            .map { [musicApp] _ in musicApp.currentTrack }
            .prepend(track)
            .handleEvents(receiveOutput: { track in
                os_log(.info, log: log, "Starting recording of new track %s.",
                       track?.description ?? "NO_TRACK")
            })
            .sink { [unowned self] newTrack in
                if let newTrack = newTrack {
                    do {
                        let newRecordingLocation = try self.tempPathGenerator.generateFilePath()
                        let recordingConfiguration = RecordingConfiguration(
                            fileLocation: newRecordingLocation,
                            track: newTrack
                        )

                        try recordingEngine.startNewRecording(using: recordingConfiguration)
                        self.withStateLock { self.inProgressTracks[newRecordingLocation] = newTrack }
                    } catch {
                        self.stopRecording()
                    }
                } else {
                    os_log(.info, log: log, "New track id is nil, ending recording session.")
                    self.stopRecording()
                }
            }

        musicApp.play()
        state = .recording
    }

    private func locked_stopRecording() {
        guard state.canTransition(to: .endingRecording) else { return }

        state = .endingRecording
        os_log(.info, log: log, "Recording Session is ending.")

        activeRecordingEngine?.stopRecording { [weak self] in self?.state = .notRecording }
        recordingCancellable = nil
    }

    private func applyMusicAppConfiguration(_ configuration: Configuration) {
        if configuration.shouldDisableShuffling {
            musicApp.setShuffleEnabled(false)
        }

        if configuration.shouldDisableRepeat {
            musicApp.setRepeatEnabled(false)
        }
    }

    private func withStateLock<T>(_ block: () throws -> T) rethrows -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return try block()
    }
}

extension SessionCoordinator: RecordingEngineDelegate {
    func recordingEngine(_ recordingEngine: RecordingEngine, didFinishRecordingTo fileURL: URL, withError error: Error?) {
        guard error == nil else {
            let failedTrack = withStateLock { inProgressTracks.removeValue(forKey: fileURL) }
            os_log(.error, log: log, "Recording session failed to record %s with error %{public}s",
                   failedTrack?.description ?? "UNKNOWN_TRACK", String(describing: error!))

            stopRecording() // Async here to get off the 
            return
        }

        stateLock.lock()
        let maybeRecordedTrack = inProgressTracks.removeValue(forKey: fileURL)
        let sessionConfig = _configuration
        stateLock.unlock()

        guard let recordedTrack = maybeRecordedTrack else {
            assertionFailure("Recording engine has reported completion of a recording to \(fileURL) that is not being tracked by the session.")
            return
        }

        recordingProcessor.enqueueRecording(at: fileURL, forTrack: recordedTrack, recordedWith: sessionConfig) { result in
            switch result {
            case .success(let finalURL):
                os_log(.info, log: log, "Finalized recording of %s to %s.",
                       recordedTrack.description, finalURL.path)
            case .failure(let error):
                os_log(.error, log: log, "Failed to finalize recording of %s with error %{public}s.",
                       recordedTrack.description, String(describing: error))
            }
        }
    }
}
