//
//  SpotijackSessionTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
@testable import LibSpotijack

/// Tests how SpotijackSession controls Audio Hijack Pro's state
internal class SpotijackSessionAudioHijackTests: XCTestCase {
    // MARK: - Mute Tests
    func testGetSessionMuteState() {
        let expectedMuteState = true
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        ahp._sessions.first(where: { $0._name == "Spotijack" })?.setSpeakerMuted(expectedMuteState)

        XCTAssertEqual(session.isMuted, expectedMuteState)
    }

    func testSetSessionMuteState() {
        let expectedMuteState = true
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let spotijackAHPSession = ahp._sessions.first(where: { $0._name == "Spotijack" })!

        session.isMuted = expectedMuteState

        XCTAssertEqual(spotijackAHPSession._speakerMuted, expectedMuteState)
    }

    func testChangeMuteStatePostsNotification() {
        let expectedMuteState = true
        var receivedMuteState: Bool?

        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        let obs = session.notificationCenter.addObserver(forType: MuteStateDidChange.self,
                                                         object: session,
                                                         queue: .main,
                                                         using: { noti in receivedMuteState = noti.newMuteState })

        session.isMuted = expectedMuteState

        XCTAssertEqual(expectedMuteState, receivedMuteState)
    }

    // MARK: - AHP Session Access
    func testAccessingAHPSessionStartsHijacking() {
        let expectedHijackingState = true
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let spotijackAHPSession = ahp._sessions.first(where: { $0._name == "Spotijack" })!

        spotijackAHPSession.stopHijacking()

        _ = session.spotijackSessionBridge

        XCTAssertEqual(spotijackAHPSession._hijacked, expectedHijackingState)
    }

    // MARK: - Recording Tests
    func testGetRecordingState() {
        let expectedRecordingState = true
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let spotijackAHPSession = ahp._sessions.first(where: { $0._name == "Spotijack" })!
        spotijackAHPSession.startRecording()

        XCTAssertEqual(session.isRecording, expectedRecordingState)
    }

    func testSetRecordingState() {
        let expectedRecordingState = true
        let (session, _, ahp) = SpotijackSessionManager.makeStandardApplications()
        let spotijackAHPSession = ahp._sessions.first(where: { $0._name == "Spotijack" })!

        session.isRecording = expectedRecordingState
        XCTAssertEqual(spotijackAHPSession._recording, expectedRecordingState)
    }

    func testChangeRecordingStatePostsNotification() {
        let expectedRecordingState = true
        var receivedRecordingState: Bool?

        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()
        let obs = session.notificationCenter.addObserver(forType: RecordingStateDidChange.self,
                                                         object: session,
                                                         queue: .main,
                                                         using: { noti in receivedRecordingState = noti.isRecording })
        session.isRecording = true

        XCTAssertNotNil(receivedRecordingState)
        XCTAssertEqual(receivedRecordingState, expectedRecordingState)
    }

}
