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

import os.log

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "SessionCoordinator")

public final class SessionCoordinator {

    // MARK: - Nested Types

    public typealias RecorderFactory = (CaptureDevice) throws -> RecordingEngine

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

    @Published public private(set) var isRecording = false

    // MARK: - Private Properties

    private let musicApp: MusicApplication

    private let recorderFactory: RecorderFactory

    private var activeRecordingEngine: RecordingEngine?
    private var recordingCancellable: AnyCancellable?

    // MARK: - Initializers

    public init(musicApp: MusicApplication, recorderFactory: @escaping RecorderFactory) {
        self.musicApp = musicApp
        self.recorderFactory = recorderFactory
    }

    // MARK: - Public Methods

    public func startRecording(from captureDevice: CaptureDevice, using configuration: Configuration) throws {
        guard !isRecording,
              let currentTrack = musicApp.currentTrack else {
            return
        }

        let recordingEngine = try recorderFactory(captureDevice)
        activeRecordingEngine = recordingEngine

        musicApp.pause()
        musicApp.playerPosition = 0
        applyMusicAppConfiguration(configuration)

        recordingCancellable = musicApp.trackIDPublisher
            .removeDuplicates()
            .handleEvents(receiveOutput: { trackID in
                os_log(.info, log: log, "Track ID has changed to %@", trackID ?? "NULL")
            })
            .map { [musicApp] _ in musicApp.currentTrack }
            .prepend(currentTrack)
            .sink { [unowned self] track in
                if let currentTrack = track {
                    do {
                        let newRecordingLocation = try configuration.fileNameFormatter
                            .filePath(for: currentTrack, recordedWith: configuration.audioSettings)

                        let recordingConfiguration = RecordingConfiguration(
                            fileLocation: newRecordingLocation,
                            track: currentTrack
                        )

                        try recordingEngine.startNewRecording(using: recordingConfiguration)
                    } catch {
                        stopRecording()
                    }
                } else {
                    os_log(.info, log: log, "New track id is nil, ending recording session")
                    stopRecording()
                }
            }

        musicApp.play()
        isRecording = true
    }

    public func stopRecording() {
        guard isRecording else { return }

        activeRecordingEngine?.stopRecording()
        recordingCancellable = nil

        isRecording = false
    }

    // MARK: - Private Methods

    private func applyMusicAppConfiguration(_ configuration: Configuration) {
        if configuration.shouldDisableShuffling {
            musicApp.setShuffleEnabled(false)
        }

        if configuration.shouldDisableRepeat {
            musicApp.setRepeatEnabled(false)
        }
    }
}
