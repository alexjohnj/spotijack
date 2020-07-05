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
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in MockRecordingEngine() })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertNotEqual(sut.state, .recording)
    }

    func test_startRecording_updatesRecordingState() throws {
        // Given
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in MockRecordingEngine() })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertEqual(sut.state, .recording)
    }

    func test_startRecording_doesNotStartRecording_ifAlreadyRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
    }

    func test_startRecording_createsRecordingEngine() throws {
        // Given
        var createRecorderCalled = false
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in
            createRecorderCalled = true
            return MockRecordingEngine()
        })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        XCTAssertTrue(createRecorderCalled)
    }

    func test_startRecording_updatesStateOfMusicApp() throws {
        // Given
        let musicApp = MockMusicApp()
        musicApp.playerState = .playing
        musicApp.playerPosition = 120

        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in MockRecordingEngine() })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertTrue(musicApp.pauseInvoked, "Pauses music playbcak")
        XCTAssertEqual(musicApp.playerPosition, 0, "Seeks to start of track")
        XCTAssertTrue(musicApp.playInvoked, "Resumes music playback")
    }

    func test_startRecording_tellsRecordingEngineToStartRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertTrue(recorder.startNewRecordingInvoked)
    }

    func test_startRecording_passesConfigurationToRecordingEngine() throws {
        // Given
        let track = Track.fixture()
        let musicApp = MockMusicApp()
        musicApp.currentTrack = track
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        let recordingConfiguration = try XCTUnwrap(recorder.startNewRecordingInvocations.first)
        XCTAssertEqual(recordingConfiguration.track, track)
    }

    func test_startRecording_appliesSessionConfiguration_toMusicApp() throws {
        // Given
        let musicApp = MockMusicApp()
        let sessionConfig = SessionCoordinator.Configuration(shouldDisableShuffling: true, shouldDisableRepeat: true)
        let sut = SessionCoordinator(musicApp: musicApp, configuration: sessionConfig, recorderFactory: { _, _  in MockRecordingEngine() })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertTrue(musicApp.setShuffleEnabledInvoked)
        XCTAssertTrue(musicApp.setRepeatEnabledInvoked)
    }

    func test_startRecording_doesNotChangeMusicAppState_whenSessionConfigurationDoesNotRequestIt() throws {
        // Given
        let musicApp = MockMusicApp()
        let sessionConfig = SessionCoordinator.Configuration(shouldDisableShuffling: false, shouldDisableRepeat: false)
        let sut = SessionCoordinator(musicApp: musicApp, configuration: sessionConfig, recorderFactory: { _, _  in MockRecordingEngine() })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // Then
        XCTAssertFalse(musicApp.setShuffleEnabledInvoked)
        XCTAssertFalse(musicApp.setRepeatEnabledInvoked)
    }

    // MARK: - The Recording Lifecycle

    func test_startRecording_startsANewRecording_whenCurrentTrackChanges() throws {
        // Given
        let newTrack = Track.fixture(id: "NEW-TRACK", name: "26")
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

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
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        musicApp.currentTrack = newTrack
        musicApp.trackIDSubject.send(newTrack.id)
        musicApp.trackIDSubject.send(newTrack.id)

        // Then
        XCTAssertNotEqual(recorder.startNewRecordingInvocationCount, 3)
    }

    func test_stopsRecording_WhenRecordingEngineEncountersAnError() throws {
        // Given
        struct TestError: Error { } // swiftlint:disable:this nesting
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _ in recorder })

        // When, Then
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())
        XCTAssertEqual(sut.state, .recording, "Sanity Check")

        recorder.delegate?.recordingEngine(recorder, didFinishRecordingTo: URL(fileURLWithPath: "/"), withError: TestError())
        XCTAssertEqual(sut.state, .endingRecording, "The SessionCoordinator is stopping")

        if let completion = recorder.stopRecordingInvocations.last {
            completion?()
        }

        XCTAssertEqual(sut.state, .notRecording)
    }

    func test_enqueuesRecordingForProcessing_whenRecordingFinishesSuccesfully() throws {
        // Given
        let recorder = MockRecordingEngine()
        let processor = MockRecordingProcessor()
        let musicApp = MockMusicApp()
        musicApp.currentTrack = .fixture()
        let expectedRecordingURL = URL(fileURLWithPath: "/test.m4a")
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recordingProcessor: processor, recorderFactory: { _, _ in recorder })
        sut.tempPathGenerator = TemporaryFilePathGenerator { expectedRecordingURL }

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())
        recorder.delegate?.recordingEngine(recorder, didFinishRecordingTo: expectedRecordingURL, withError: nil)

        // Then
        XCTAssertTrue(processor.processRecordingInvoked)
    }

    // MARK: - Stopping Recording

    func test_stopsRecording_whenCurrentTrackChangesToNil() throws {
        // Given
        let musicApp = MockMusicApp()
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        musicApp.currentTrack = nil
        musicApp.trackIDSubject.send(nil)

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
        XCTAssertTrue(recorder.stopRecordingInvoked)
    }

    func test_stopRecording_doesNothingIfNotRecording() {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in recorder })

        // When
        sut.stopRecording()

        // Then
        XCTAssertFalse(recorder.stopRecordingInvoked)
    }

    func test_stopRecording_updatesRecordingState() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in recorder })
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

        // When
        sut.stopRecording()

        // Then
        XCTAssertEqual(sut.state, .endingRecording)

        if let completion = recorder.stopRecordingInvocations.last {
            completion?()
        }
        XCTAssertEqual(sut.state, .notRecording)
    }

    func test_stopRecording_tellsRecordingEngineToStopRecording() throws {
        // Given
        let recorder = MockRecordingEngine()
        let sut = SessionCoordinator(musicApp: MockMusicApp(), recorderFactory: { _, _  in recorder })
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())

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
        let sut = SessionCoordinator(musicApp: musicApp, recorderFactory: { _, _  in recorder })

        // When
        try sut.startRecordingFromConvertibleDevice(FakeCaptureDevice())
        sut.stopRecording()

        // These changes should have no effect
        musicApp.currentTrack = newTrack
        musicApp.trackIDSubject.send(newTrack.id)

        // Then
        XCTAssertEqual(recorder.startNewRecordingInvocationCount, 1)
        XCTAssertTrue(recorder.stopRecordingInvoked)
    }
}
