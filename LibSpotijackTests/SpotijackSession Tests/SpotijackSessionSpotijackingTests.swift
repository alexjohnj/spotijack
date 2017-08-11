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
    func testSpotijackingGeneratesFiles() {
        let expectedRecordingCount = 2
        var receivedRecordingCount: Int?
        let spotijackingExpectation = expectation(description: "Waiting for Spotijacking process to finish")

        let (session, spotify, ahp) = SpotijackSession.makeStandardApplications()
        let recordingConfiguration = SpotijackSession.RecordingConfiguration(muteSpotify: false,
                                                                             disableShuffling: false,
                                                                             disableRepeat: false,
                                                                             pollingInterval: 0.1)
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

    func testReachingEndOfPlaybackQueuePostsInformsDelegate() {
        let spotijackingExpectation = expectation(description: "Waiting to skip final track")
        var delegateWasInformed = false
        let delegate = MockSpotijackSessionDelegate()
        delegate.onSessionDidReachEndOfPlaybackQueue = { _ in
            delegateWasInformed = true
        }

        let (session, spotify, _) = SpotijackSession.makeStandardApplications()
        session.delegate = delegate

        // Skip to final track in queue
        spotify.nextTrack()
        spotify.nextTrack()
        XCTAssertNoThrow(try session.startSpotijackSession(config: SpotijackSession.RecordingConfiguration()))

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15) {
            spotify.nextTrack()
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15) {
                spotijackingExpectation.fulfill()
            }
        }

        wait(for: [spotijackingExpectation], timeout: 1.0)

        XCTAssertTrue(delegateWasInformed)
    }
}
