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

internal class SpotijackSessionSpotijackingTests: XCTestCase {
    // MARK: - General Polling
    func testStartStopPolling() {
        let (session, _, _) = SpotijackSession.makeStandardApplications()

        session.startPolling(every: 1.0)
        XCTAssertNotNil(session._applicationPollingTimer)
        XCTAssertTrue(session.isPolling)

        session.stopPolling()
        XCTAssertFalse(session.isPolling)
        XCTAssertNil(session._applicationPollingTimer)
    }

    func testStartPollingRespectsInterval() {
        let expectedInterval: TimeInterval = 1.0
        let (session, _, _) = SpotijackSession.makeStandardApplications()

        session.startPolling(every: expectedInterval)
        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }

    // MARK: - Spotijacking Specific
    func testSpotijackingWithAsyncDelayGeneratesFiles() {
        let expectedRecordingCount = 2
        var receivedRecordingCount: Int?
        let spotijackingExpectation = expectation(description: "Waiting for Spotijacking process to finish")

        let (session, spotify, ahp) = SpotijackSession.makeStandardApplications()
        let recordingConfiguration = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                                             disableShuffling: false,
                                                                             disableRepeat: false,
                                                                             pollingInterval: 0.1,
                                                                             recordingStartDelay: 0.1)
        XCTAssertNoThrow(try session.startSpotijackSession(config: recordingConfiguration))

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
        session.stopSpotijackSession()

        XCTAssertNotNil(receivedRecordingCount)
        XCTAssertEqual(receivedRecordingCount, expectedRecordingCount)
    }

    func testSpotijackingWithoutAsyncDelayGeneratesFiles() {
        let expectedRecordingCount = 2
        let (session, spotify, ahp) = SpotijackSession.makeStandardApplications()
        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50, // Will poll manually
                                                             recordingStartDelay: 0)

        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
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

    func testReachingEndOfPlaybackQueueInformsDelegate() {
        var delegateWasInformed = false
        let delegate = MockSpotijackSessionDelegate()
        delegate.onSessionDidReachEndOfPlaybackQueue = { _ in
            delegateWasInformed = true
        }

        let (session, spotify, _) = SpotijackSession.makeStandardApplications()
        session.delegate = delegate

        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50.0,
                                                             recordingStartDelay: 0)
        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
        session._applicationPollingTimer?.fire()

        let nextTrack = {
            session._applicationPollingTimer?.fire()
            spotify.nextTrack()
            session._applicationPollingTimer?.fire()
        }

        for _ in 0..<3 { nextTrack() }

        XCTAssertTrue(delegateWasInformed)
    }

    func testReachingEndOfPlaybackQueueEndsSpotijacking() {
        let (session, spotify, _) = SpotijackSession.makeStandardApplications()
        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 50.0,
                                                             recordingStartDelay: 0.0)

        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
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
        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: expectedInterval + 1,
                                                             recordingStartDelay: 0.0)
        let (session, _, _) = SpotijackSession.makeStandardApplications()
        session.startPolling(every: expectedInterval)

        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
        XCTAssertNotEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
        session.stopSpotijackSession()

        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }

    func testEndSpotijackingWithoutPreviousPollingIntervalStopsPolling() {
        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 42.0,
                                                             recordingStartDelay: 0.0)
        let (session, _, _) = SpotijackSession.makeStandardApplications()
        session.stopPolling() // Ensure polling has not been started

        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
        session.stopSpotijackSession()

        XCTAssertNil(session._applicationPollingTimer)
    }

    func testStartNewRecordingUpdatesAudioHijackProSessionTags() {
        let (session, spotify, ahp) = SpotijackSession.makeStandardApplications()
        let ahpSession = ahp._sessions.first(where: { $0.name == "Spotijack" })!
        let expectedTrack = spotify._playbackQueue.first!

        let config = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                             disableShuffling: false,
                                                             disableRepeat: false,
                                                             pollingInterval: 1,
                                                             recordingStartDelay: 0.0)

        XCTAssertNoThrow(try session.startSpotijackSession(config: config))
        session.stopSpotijackSession()

        XCTAssertEqual(ahpSession._titleTag, expectedTrack.name)
        XCTAssertEqual(ahpSession._albumTag, expectedTrack.album)
        XCTAssertEqual(ahpSession._artistTag, expectedTrack.artist)
        XCTAssertEqual(ahpSession._albumArtistTag, expectedTrack.albumArtist)
        XCTAssertEqual(ahpSession._discNumberTag, String(describing: expectedTrack.discNumber))
        XCTAssertEqual(ahpSession._trackNumberTag, String(describing: expectedTrack.trackNumber))
    }
}
