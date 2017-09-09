//
//  SpotijackSessionSpotijackingTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 11/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
import Foundation
@testable import LibSpotijack

//swiftlint:disable:next type_body_length
internal class SpotijackSessionSpotijackingTests: XCTestCase {
    // MARK: - General Polling
    func testStartStopPolling() {
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()

        session.startPolling(every: 1.0)
        XCTAssertNotNil(session._applicationPollingTimer)
        XCTAssertTrue(session.isPolling)

        session.stopPolling()
        XCTAssertFalse(session.isPolling)
        XCTAssertNil(session._applicationPollingTimer)
    }

    func testStartPollingRespectsInterval() {
        let expectedInterval: TimeInterval = 1.0
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()

        session.startPolling(every: expectedInterval)
        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }

    // MARK: - Spotijacking Specific
    func testSpotijackingWithAsyncDelayGeneratesFiles() {
        let expectedRecordingCount = 2
        var receivedRecordingCount: Int?
        let spotijackingExpectation = expectation(description: "Waiting for Spotijacking process to finish")

        let (session, spotify, ahp) = SpotijackSessionManager.makeStandardApplications()
        let recordingConfiguration = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                                             disableShuffling: false,
                                                                             disableRepeat: false,
                                                                             pollingInterval: 0.1,
                                                                             recordingStartDelay: 0.1)
        XCTAssertNoThrow(try session.startSpotijacking(config: recordingConfiguration))

        // The delays here are to account for the pause Spotijack takes between starting new recordings.
        let queue = DispatchQueue.global(qos: .userInitiated)
        let waitTime = { DispatchTime.now() + 0.15 }
        queue.asyncAfter(deadline: waitTime()) {
            spotify.nextTrack()
            queue.asyncAfter(deadline: waitTime()) {
                spotify.nextTrack()
                queue.asyncAfter(deadline: waitTime()) {
                    receivedRecordingCount = ahp._recordings.count
                    spotijackingExpectation.fulfill()
                }
            }
        }

        wait(for: [spotijackingExpectation], timeout: 1.0)
        session.stopSpotijacking()

        XCTAssertNotNil(receivedRecordingCount)
        XCTAssertEqual(receivedRecordingCount, expectedRecordingCount)
    }

    func testSpotijackingWithoutAsyncDelayGeneratesFiles() {
        let expectedRecordingCount = 2
        let (session, spotify, ahp) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50, // Will poll manually
                                                             recordingStartDelay: 0)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        let nextTrack = {
            session._applicationPollingTimer?.fire()
            spotify.nextTrack()
            session._applicationPollingTimer?.fire()
        }

        // Simulate three track changes producing two recordings
        nextTrack()
        nextTrack()

        XCTAssertEqual(ahp._recordings.count, expectedRecordingCount)
    }

    func testEndingSpotijackingGeneratesARecordingFile() {
        let expectedRecordingCount = 3
        let (session, spotify, ahp) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50,
                                                             recordingStartDelay: 0)
        let nextTrack = {
            session._applicationPollingTimer?.fire()
            spotify.nextTrack()
            session._applicationPollingTimer?.fire()
        }

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        nextTrack() // Recording 1
        nextTrack() // Recording 2
        session.stopSpotijacking() // Should generate recording 3

        XCTAssertEqual(ahp._recordings.count, expectedRecordingCount)
    }

    func testReachingEndOfPlaybackQueuePostsNotification() {
        var notificationWasPosted = false

        let (session, spotify, _) = SpotijackSessionManager.makeStandardApplications()
        let obs = session.notificationCenter.addObserver(forType: DidReachEndOfPlaybackQueue.self,
                                                         object: session,
                                                         queue: .main,
                                                         using: { _ in notificationWasPosted = true })

        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50.0,
                                                             recordingStartDelay: 0)
        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        session._applicationPollingTimer?.fire()

        let nextTrack = {
            session._applicationPollingTimer?.fire()
            spotify.nextTrack()
            session._applicationPollingTimer?.fire()
        }

        for _ in 0..<3 { nextTrack() }

        XCTAssertTrue(notificationWasPosted)
    }

    func testReachingEndOfPlaybackQueueEndsSpotijacking() {
        let (session, spotify, _) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50.0,
                                                             recordingStartDelay: 0.0)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        let nextTrack = {
            session._applicationPollingTimer?.fire()
            spotify.nextTrack()
            session._applicationPollingTimer?.fire()
        }

        for _ in 0..<3 { nextTrack() }

        XCTAssertFalse(session.isSpotijacking)
    }

    func testEndingSpotijackingResumesPollingAtPreviousInterval() {
        let expectedInterval = 42.0
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: expectedInterval + 1,
                                                             recordingStartDelay: 0.0)
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        session.startPolling(every: expectedInterval)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        XCTAssertNotEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
        session.stopSpotijacking()

        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }

    func testEndSpotijackingWithoutPreviousPollingIntervalStopsPolling() {
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 42.0,
                                                             recordingStartDelay: 0.0)
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        session.stopPolling() // Ensure polling has not been started

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        session.stopSpotijacking()

        XCTAssertNil(session._applicationPollingTimer)
    }

    func testStartNewRecordingUpdatesAudioHijackProSessionTags() {
        let (session, spotify, ahp) = SpotijackSessionManager.makeStandardApplications()
        let ahpSession = ahp._sessions.first(where: { $0.name == "Spotijack" })!
        let expectedTrack = spotify._playbackQueue.first!

        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 1,
                                                             recordingStartDelay: 0.0)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        session.stopSpotijacking()

        XCTAssertEqual(ahpSession._titleTag, expectedTrack.name)
        XCTAssertEqual(ahpSession._albumTag, expectedTrack.album)
        XCTAssertEqual(ahpSession._artistTag, expectedTrack.artist)
        XCTAssertEqual(ahpSession._albumArtistTag, expectedTrack.albumArtist)
        XCTAssertEqual(ahpSession._discNumberTag, String(describing: expectedTrack.discNumber))
        XCTAssertEqual(ahpSession._trackNumberTag, String(describing: expectedTrack.trackNumber))
    }

    /// Test ending a recording via the Audio Hijack Pro application also ends Spotijacking. Failure to do so would lead
    /// to an inconsistent internal state.
    func testEndRecordingViaAHPEndsSpotijacking() {
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50.0,
                                                             recordingStartDelay: 0.0)
        let ahpSession = ahp._sessions.first(where: { $0.name == "Spotijack" })!

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        ahpSession.stopRecording()
        session.pollSpotify()
        session.pollAudioHijackPro()

        XCTAssertFalse(session.isSpotijacking)
    }

    func testEndingSpotijackingPostsNotification() {
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration()
        var wasNotified = false

        let obs = session.notificationCenter.addObserver(forType: DidEndSpotijacking.self,
                                                         object: session,
                                                         queue: .main,
                                                         using: { _ in wasNotified = true })

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        session.stopSpotijacking()

        XCTAssertTrue(wasNotified)
    }

    // MARK: - Recording Configuration
    func testStartSpotijackingRespectsDisableShufflingConfiguration() {
        let (session, spotify, _) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: true,
                                                             disableShuffling: true,
                                                             disableRepeat: true,
                                                             pollingInterval: 50,
                                                             recordingStartDelay: 0.0)
        spotify.setShuffling(true)
        XCTAssertNoThrow(try session.startSpotijacking(config: config))

        XCTAssertFalse(spotify.shuffling)
    }

    func testStartSpotijackingRespectsDisableRepeatingConfiguration() {
        let (session, spotify, _) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: true,
                                                             disableShuffling: true,
                                                             disableRepeat: true,
                                                             pollingInterval: 50,
                                                             recordingStartDelay: 0.0)

        spotify.setRepeating(true)
        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        XCTAssertFalse(spotify.repeating)
    }

    func testStartSpotijackingRespectsMuteSessionRecordingConfiguration() {
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let ahpSession = ahp._sessions.first(where: { $0.name == "Spotijack" })!
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: true,
                                                             disableShuffling: true,
                                                             disableRepeat: true,
                                                             pollingInterval: 50,
                                                             recordingStartDelay: 0.0)

        ahpSession.setSpeakerMuted(true)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        XCTAssertTrue(ahpSession.speakerMuted)
    }

    func testStartSpotijackingRespectsRecordingConfigurationPollingInterval() {
        let expectedInterval = 50.0
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        let config = SpotijackSessionManager.RecordingConfiguration(muteSpotify: true,
                                                             disableShuffling: true,
                                                             disableRepeat: true,
                                                             pollingInterval: expectedInterval,
                                                             recordingStartDelay: 0.0)

        XCTAssertNoThrow(try session.startSpotijacking(config: config))
        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }
}
