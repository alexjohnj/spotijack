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

// swiftlint:disable file_length
internal class LibSpotijackTests: XCTestCase {
    override func setUp() {
        super.setUp()

        // Launch applications if needed
        let launchExpect = expectation(description: "Waiting to establish session.")
        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }
            // Reset application state. Deliberately avoiding using
            // SpotijackSession API here.
            // AHP
            guard case .ok(let ahpSession) = session.spotijackSessionBridge else {
                XCTFail()
                return
            }
            ahpSession.stopRecording!()
            ahpSession.stopHijacking!()
            ahpSession.setSpeakerMuted!(false)

            // Spotify
            session.spotifyBridge.pause!()
            session.spotifyBridge.setPlayerPosition!(0.0)
            session.spotifyBridge.setRepeating!(false)
            session.spotifyBridge.setShuffling!(false)

            launchExpect.fulfill()
        }

        wait(for: [launchExpect], timeout: 5.0)

        // Reset SessionManager
        SpotijackSessionManager.shared.spotijackSession = nil
    }

    override func tearDown() {
        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            session.isRecording = false
            session.isMuted = false

            session.spotijackSessionBridge.value?.stopHijacking!()
            session.spotifyBridge.pause!()
        }

        super.tearDown()
    }
}

// MARK: - Muting Tests
extension LibSpotijackTests {
    /// Test muting the Spotijack session works and does not trigger an error.
    func testMuteSpotijackSession() {
        let muteExpect = expectation(description: "Waiting to determine mute state")
        let muteErrorObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
            forType: DidEncounterError.self,
            object: SpotijackSessionManager.shared,
            queue: nil, using: { _ in XCTFail("Muting Spotijack session triggered an error.") }
        )

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

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

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            muteNotificationObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
                forType: MuteStateDidChange.self,
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

        SpotijackSessionManager.shared.establishSession { sessionResult in
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

// MARK: - Recording Tests
extension LibSpotijackTests {
    func testChangeSpotijackRecordingState() {
        let recordingChangeExpect = expectation(description: "Waiting for recording state to change.")
        var recordingErrorObserver: NotificationObserver? = nil

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            recordingErrorObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
                forType: DidEncounterError.self,
                object: SpotijackSessionManager.shared,
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

        SpotijackSessionManager.shared.establishSession { sessionResult in
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

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            let newRecordingState = !session.isRecording

            notificationObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
                forType: RecordingStateDidChange.self,
                object: SpotijackSessionManager.shared,
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

// MARK: - Currently Playing Song Tests
extension LibSpotijackTests {
    func testGetCurrentTrackWorks() {
        let currentTrackExpect = expectation(description: "Waiting to get current track")
        var errorNotificationObserver: NotificationObserver? = nil

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            errorNotificationObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
                forType: DidEncounterError.self,
                object: SpotijackSessionManager.shared,
                queue: nil,
                using: { noti in
                    XCTFail(String(describing: noti.error))
            })

            // Spotify takes a bit of time to switch tracks depending on network
            // speed. The infinite while loops here are to give it chance to switch.
            // We'll wait for 5 seconds, with the test failing otherwise.
            // Obviously we don't wan't to block the main thread otherwise the `wait(for:timeout:)`
            // call will be blocked so we do the polling on a background queue but
            // all tests are run on the main queue.
            DispatchQueue.global(qos: .userInitiated).async {
                // Reset to a known track first
                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(FakeHappy.uri, inContext: nil)
                }
                while session.currentTrack?.name != FakeHappy.name { continue }

                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(LetTheFlamesBegin.uri, inContext: nil)
                }
                while session.currentTrack?.name != LetTheFlamesBegin.name { continue }

                DispatchQueue.main.sync {
                    XCTAssertEqual(session.currentTrack?.name, LetTheFlamesBegin.name)
                    XCTAssertEqual(session.currentTrack?.artist, LetTheFlamesBegin.artist)
                    XCTAssertEqual(session.currentTrack?.album, LetTheFlamesBegin.album)
                    currentTrackExpect.fulfill()
                }
            }
        }

        wait(for: [currentTrackExpect], timeout: 5.0)
    }

    func testChangeTrackPostsNotification() {
        let changeTrackExpect = expectation(description: "Waiting for track change notification")
        var trackChangeObserver: NotificationObserver? = nil

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            trackChangeObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
                forType: TrackDidChange.self,
                object: SpotijackSessionManager.shared,
                queue: nil,
                using: { _ in
                    changeTrackExpect.fulfill()
            })

            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(LetTheFlamesBegin.uri, inContext: nil)
                }

                while session.currentTrack?.name != LetTheFlamesBegin.name { continue }

                session.startPolling(every: 0.1)

                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(FakeHappy.uri, inContext: nil)
                }
            }
        }

        wait(for: [changeTrackExpect], timeout: 5.0)
    }
}

// - MARK: - Polling Tests
extension LibSpotijackTests {
    func testPollingStatusWorks() {
        let statusExpectation = expectation(description: "Waiting to get polling status.")
        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            session.startPolling(every: 0.5)
            XCTAssertTrue(session.isPolling)

            session.stopPolling()
            XCTAssertFalse(session.isPolling)

            statusExpectation.fulfill()
        }

        wait(for: [statusExpectation], timeout: 5.0)
    }
}

// MARK: - Spotijacking Tests
extension LibSpotijackTests {
    func testSpotijacking() {
        let spotijackingExpectation = expectation(description: "Waiting to Spotijack things")

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            let originalRecordingCount = session.audioHijackBridge.audioRecordings!().count

            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(LetTheFlamesBegin.uri, inContext: nil)
                }

                while session.currentTrack?.name != LetTheFlamesBegin.name { continue }

                DispatchQueue.main.sync {
                    do {
                        let config = SpotijackSession.RecordingConfiguration(muteSpotify: true,
                                                                             disableShuffling: true,
                                                                             disableRepeat: true,
                                                                             pollingInterval: 0.1)
                        try session.startSpotijackSession(config: config)
                    } catch (let error) {
                        XCTFail(String(describing: error))
                    }

                    XCTAssertTrue(session.isSpotijacking)
                    XCTAssertTrue(session.isMuted)
                    XCTAssertFalse(session.spotifyBridge.shuffling!)
                    XCTAssertFalse(session.spotifyBridge.repeating!)
                }
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 5.0) {
                    // Trigger a track change
                    DispatchQueue.main.sync {
                        session.spotifyBridge.playTrack!(FakeHappy.uri, inContext: nil)
                    }

                    while session.currentTrack?.name != FakeHappy.name { continue }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        session.stopSpotijackSession()
                        XCTAssertFalse(session.isSpotijacking)
                        XCTAssertFalse(session.isRecording)

                        let newRecordingCount = session.audioHijackBridge.audioRecordings!().count
                        XCTAssertEqual(originalRecordingCount, newRecordingCount - 2)

                        spotijackingExpectation.fulfill()
                    }
                }
            }
        }
        wait(for: [spotijackingExpectation], timeout: 30.0)
    }

    func testStartNewRecordingUpdatesRecordingMetadata() {
        let metadataExpect = expectation(description: "Waiting to check AHP metadata")
        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.sync {
                    session.spotifyBridge.playTrack!(LetTheFlamesBegin.uri, inContext: nil)
                }

                while session.currentTrack?.name != LetTheFlamesBegin.name { continue }

                DispatchQueue.main.sync {
                    do {
                        let config = SpotijackSession.RecordingConfiguration(muteSpotify: true,
                                                                             disableShuffling: true,
                                                                             disableRepeat: true,
                                                                             pollingInterval: 0.1)
                        try session.startSpotijackSession(config: config)
                    } catch (let error) {
                        XCTFail(String(describing: error))
                        return
                    }

                    guard case .ok(let spotijackRecordingSession) = session.spotijackSessionBridge else {
                        XCTFail()
                        return
                    }

                    XCTAssertEqual(spotijackRecordingSession.titleTag, LetTheFlamesBegin.name)
                    XCTAssertEqual(spotijackRecordingSession.albumTag, LetTheFlamesBegin.album)
                    XCTAssertEqual(spotijackRecordingSession.artistTag, LetTheFlamesBegin.artist)

                    session.stopSpotijackSession()
                    metadataExpect.fulfill()
                }
            }
        }

        wait(for: [metadataExpect], timeout: 5.0)
    }

    func testReachingEndOfPlaybackQueuePostsNotificationAndEndsSpotijacking() {
        let notiExpect = expectation(description: "Waiting for a notification that the queue has ended.")
        let notiObserver = SpotijackSessionManager.shared.notiCenter.addObserver(
            forType: DidReachEndOfPlaybackQueue.self,
            object: SpotijackSessionManager.shared,
            queue: nil,
            using: { _ in
                XCTAssertFalse(SpotijackSessionManager.shared.isSpotijacking)
                notiExpect.fulfill()
        })

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.sync {
                    do {
                        let config = SpotijackSession.RecordingConfiguration()
                        try session.startSpotijackSession(config: config)
                        session.spotifyBridge.playTrack!(BabesNeverDieOutro.uri,
                                                         inContext: "spotify:album:5t8fEQAEiAUpKzGPT1ygdy")
                    } catch (let error) {
                        XCTFail(error.localizedDescription)
                    }
                }

                while session.currentTrack?.id != BabesNeverDieOutro.uri { continue }

                DispatchQueue.main.sync {
                    session.spotifyBridge.play!()
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
                        DispatchQueue.main.sync {
                            session.spotifyBridge.setPlayerPosition!(70.0)
                        }
                    }
                }
            }
        }

        wait(for: [notiExpect], timeout: 20.0)
    }

    func testEndingSpotijackingResumesPollingAtPreviousFrequency() {
        let exp = expectation(description: "Waiting for Spotijack block to execute")

        SpotijackSessionManager.shared.establishSession { sessionResult in
            guard case .ok(let session) = sessionResult else {
                XCTFail()
                return
            }

            let initialInterval: TimeInterval = 2.0
            let spotijackingInterval: TimeInterval = 1.0

            let config = SpotijackSession.RecordingConfiguration(muteSpotify: true,
                                                                 disableShuffling: true,
                                                                 disableRepeat: true,
                                                                 pollingInterval: spotijackingInterval)

            session.startPolling(every: initialInterval)
            do {
                try session.startSpotijackSession(config: config)
            } catch (let error) {
                XCTFail(error.localizedDescription)
            }
            session.stopSpotijackSession()

            XCTAssertEqual(session._applicationPollingTimer?.timeInterval, initialInterval)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }
}
