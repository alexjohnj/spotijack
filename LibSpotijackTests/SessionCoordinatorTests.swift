//
//  SpotijackSessionManagerTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import XCTest
import AVFoundation
@testable import LibSpotijack

final class SessionCoordinatorTests: XCTestCase {

    func test_startRecording_doesNotStartRecording_ifMusicAppIsNotPlaying() throws {
        // Given
        let musicApp = MockMusicApp()
        musicApp.currentTrack = nil
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in MockRecordingEngine() })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // Then
        XCTAssertFalse(sut.isRecording)
    }

    func test_startRecording_updatesRecordingState() throws {
        // Given
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in MockRecordingEngine() })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // Then
        XCTAssertTrue(sut.isRecording)
    }

    func test_startRecording_doesNotStartRecording_ifAlreadyRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in recorder })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
    }

    func test_startRecording_createsRecordingEngine() throws {
        // Given
        var createRecorderCalled = false
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in
            createRecorderCalled = true
            return MockRecordingEngine()
        })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        XCTAssertTrue(createRecorderCalled)
    }

    func test_startRecording_updatesStateOfMusicApp() throws {
        // Given
        let musicApp = MockMusicApp()
        musicApp.playerState = .playing
        musicApp.playerPosition = 120

        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in MockRecordingEngine() })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // Then
        XCTAssertTrue(musicApp.pauseInvoked, "Pauses music playbcak")
        XCTAssertEqual(musicApp.playerPosition, 0, "Seeks to start of track")
        XCTAssertTrue(musicApp.playInvoked, "Resumes music playback")
    }

    func test_startRecording_tellsRecordingEngineToStartRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in recorder })
        let sessionConfig = SessionCoordinator.Configuration()

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: sessionConfig)

        // Then
        XCTAssertTrue(recorder.startNewRecordingInvoked)
    }

    func test_startRecording_passesConfigurationToRecordingEngine() throws {
        // Given
        let track = Track.fixture()
        let musicApp = MockMusicApp()
        musicApp.currentTrack = track
        let recorder = MockRecordingEngine()

        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in recorder })
        let sessionConfig = SessionCoordinator.Configuration()

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: sessionConfig)

        // Then
        let recordingConfiguration = try XCTUnwrap(recorder.startNewRecordingInvocations.first)
        XCTAssertEqual(recordingConfiguration.track, track)
    }

    func test_startRecording_appliesSessionConfiguration_toMusicApp() throws {
        // Given
        let musicApp = MockMusicApp()

        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in MockRecordingEngine() })
        let sessionConfig = SessionCoordinator.Configuration(shouldDisableShuffling: true, shouldDisableRepeat: true)

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: sessionConfig)

        // Then
        XCTAssertTrue(musicApp.setShuffleEnabledInvoked)
        XCTAssertTrue(musicApp.setRepeatEnabledInvoked)
    }

    func test_startRecording_doesNotChangeMusicAppState_wheSessionConfigurationDoesNotRequestIt() throws {
        // Given
        let musicApp = MockMusicApp()

        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in MockRecordingEngine() })
        let sessionConfig = SessionCoordinator.Configuration(shouldDisableShuffling: false, shouldDisableRepeat: false)

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: sessionConfig)

        // Then
        XCTAssertFalse(musicApp.setShuffleEnabledInvoked)
        XCTAssertFalse(musicApp.setRepeatEnabledInvoked)
    }

    func test_startRecording_startsANewRecording_whenCurrentTrackChanges() throws {
        // Given
        let newTrack = Track.fixture(id: "NEW-TRACK", name: "26")
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in recorder })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        musicApp.currentTrack = newTrack
        musicApp.trackIDSubject.send(newTrack.id)

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 2)
        let newRecordingConfiguration = try XCTUnwrap(recorder.startNewRecordingInvocations.last)
        XCTAssertEqual(newRecordingConfiguration.track, newTrack)
    }

    func test_doesNotStartNewRecording_whenTrackIDIsUnchanged() throws {
        // Given
        let newTrack = Track.fixture(id: "NEW-TRACK", name: "26")
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in recorder })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        musicApp.currentTrack = newTrack
        musicApp.trackIDSubject.send(newTrack.id)
        musicApp.trackIDSubject.send(newTrack.id)

        // Then
        XCTAssertNotEqual(recorder.startNewRecordingInvocationCount, 3)
    }

    // MARK: -

    func test_stopsRecording_whenCurrentTrackChangesToNil() throws {
        // Given
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in recorder })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        musicApp.currentTrack = nil
        musicApp.trackIDSubject.send(nil)

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
        XCTAssertTrue(recorder.stopRecordingInvoked)
    }

    func test_stopRecording_doesNothingIfNotRecording() {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in recorder })

        // When
        sut.stopRecording()

        // Then
        XCTAssertFalse(recorder.stopRecordingInvoked)
    }

    func test_stopRecording_updatesRecordingState() throws {
        // Given
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in MockRecordingEngine() })
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // When
        sut.stopRecording()

        // Then
        XCTAssertFalse(sut.isRecording)
    }

    func test_stopRecording_tellsRecordingEngineToStopRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _ in recorder })
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())

        // When
        sut.stopRecording()

        // Then
        XCTAssertTrue(recorder.stopRecordingInvoked)
    }

    func test_stopRecording_stopsObservingPlayerTrackChanges() throws {
        // Given
        let newTrack = Track.fixture(id: "NEW-TRACK", name: "26")
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _ in recorder })

        // When
        try sut.startRecording(from: FakeCaptureDevice(), using: SessionCoordinator.Configuration())
        sut.stopRecording()

        // These changes should have no effect
        musicApp.currentTrack = newTrack
        musicApp.trackIDSubject.send(newTrack.id)

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
        XCTAssertTrue(recorder.stopRecordingInvoked)
    }
}
