//
//  LibSpotijackTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 13/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
import TypedNotification
import Result
@testable import LibSpotijack

let spotifyBundle = "com.spotify.client"
let audioHijackBundle = "com.rogueamoeba.AudioHijackPro2"

class LibSpotijackTests: XCTestCase {
    override func setUp() {
        super.setUp()

        killAllApplications()
        let launchExpect = expectation(description: "Waiting to establish session.")
        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok = sessionResult else {
                XCTFail()
                return
            }
            launchExpect.fulfill()
        }

        wait(for: [launchExpect], timeout: 5.0)
    }

    override func tearDown() {
        super.tearDown()

        killAllApplications()
    }

    func killAllApplications() {
        let spotifyKillExpect = expectation(description: "Waiting for Spotify to terminate.")
        let audioHijackKillExpect = expectation(description: "Waiting for AHP to terminate.")
        var spotifyObserver: NSKeyValueObservation? = nil
        var audioHijackObserver: NSKeyValueObservation? = nil

        if let spotify = NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundle).first {
            spotifyObserver = spotify.observe(\.isTerminated) { (observer, _) in
                if observer.isTerminated == true {
                    spotifyKillExpect.fulfill()
                }
            }

            spotify.forceTerminate()
        } else {
            spotifyKillExpect.fulfill()
        }

        if let audioHijack = NSRunningApplication.runningApplications(withBundleIdentifier: audioHijackBundle).first {
            audioHijackObserver = audioHijack.observe(\.isTerminated) { (observer, _) in
                if observer.isTerminated == true {
                    audioHijackKillExpect.fulfill()
                }
            }

            audioHijack.forceTerminate()
        } else {
            audioHijackKillExpect.fulfill()
        }

        wait(for: [audioHijackKillExpect, spotifyKillExpect], timeout: 10.0)
    }
}

//MARK: Muting Tests
extension LibSpotijackTests {
    /// Test muting the Spotijack session works and does not trigger an error.
    func testMuteSpotijackSession() {
        let muteExpect = expectation(description: "Waiting to determine mute state")
        var muteErrorObserver: NotificationObserver? = nil

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            muteErrorObserver = session.notiCenter.addObserver(
                forType: SpotijackSessionManager.DidEncounterError.self,
                object: session,
                queue: nil,
                using: ({ (_) in XCTFail("Muting Spotijack session triggered an error.")}))

            let newMuteState = !session.isMuted
            session.isMuted = newMuteState
            XCTAssertEqual(session.isMuted, newMuteState)

            session.isMuted = !newMuteState
            XCTAssertEqual(session.isMuted, !newMuteState)

            muteExpect.fulfill()
        }

        wait(for: [muteExpect], timeout: 5.0)
    }

    func testMuteSpotijackSessionPostsNotification() {
        let muteNotificationExpect = expectation(description: "Waiting for a MuteStateDidChange notification")
        var muteNotificationObserver: NotificationObserver? = nil

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            muteNotificationObserver = session.notiCenter.addObserver(
                forType: SpotijackSessionManager.MuteStateDidChange.self,
                object: nil,
                queue: nil,
                using: ({ noti in
                    XCTAssertEqual(noti.newMuteState, session.isMuted)
                    muteNotificationExpect.fulfill()
            }))
            session.isMuted = !session.isMuted
        }

        wait(for: [muteNotificationExpect], timeout: 5.0)
    }

    func testMuteSpotijackSessionStartsHijacking() {
        let hijackExpect = expectation(description: "Waiting for Spotijack session to start hijacking")

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            session.spotijackSessionBridge.value?.stopHijacking!()
            session.isMuted = !session.isMuted

            XCTAssertTrue(session.spotijackSessionBridge.value?.hijacked ?? false)
            hijackExpect.fulfill()
        }

        wait(for: [hijackExpect], timeout: 5.0)
    }
}

//MARK: Recording Tests
extension LibSpotijackTests {
    func testChangeSpotijackRecordingState() {
        let recordingChangeExpect = expectation(description: "Waiting for recording state to change.")
        var recordingErrorObserver: NotificationObserver? = nil

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            recordingErrorObserver = session.notiCenter.addObserver(
                forType: SpotijackSessionManager.DidEncounterError.self,
                object: session,
                queue: nil,
                using: { noti in
                    XCTFail("Error when changing recording state \(noti.error)")
                })

            let newRecordingState = !session.isRecording
            session.isRecording = newRecordingState
            XCTAssertEqual(session.isRecording, newRecordingState)

            session.isRecording = !newRecordingState
            XCTAssertEqual(session.isRecording, !newRecordingState)

            session.isRecording = false // End any recordings
            XCTAssertFalse(session.isRecording)

            recordingChangeExpect.fulfill()
        }

        wait(for: [recordingChangeExpect], timeout: 5.0)
    }

    func testChangeSpotijackRecordingStatesStartsHijacking() {
        let hijackExpect = expectation(description: "Waiting for Spotijack session to start hijacking")

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            session.isRecording = false
            session.spotijackSessionBridge.value?.stopHijacking!()
            session.isRecording = true

            XCTAssertTrue(session.spotijackSessionBridge.value?.hijacked ?? false)
            hijackExpect.fulfill()
        }

        wait(for: [hijackExpect], timeout: 5.0)
    }

    func testChangeSpotijackRecordingStatePostsNotification() {
        let notificationExpect = expectation(description: "Waiting for recording status did change notification")
        var notificationObserver: NotificationObserver? = nil

        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            let newRecordingState = !session.isRecording

            notificationObserver = session.notiCenter.addObserver(
                forType: SpotijackSessionManager.RecordingStateDidChange.self,
                object: session,
                queue: nil,
                using: { (noti) in
                    XCTAssertEqual(newRecordingState, noti.isRecording)
                    notificationExpect.fulfill()
            })

            session.isRecording = newRecordingState
        }

        wait(for: [notificationExpect], timeout: 5.0)
    }
}
