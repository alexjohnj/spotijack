//
//  SpotijackSessionSpotifyTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
@testable import LibSpotijack

/// Tests how SpotijackSession controls Spotify's state
internal class SpotijackSessionSpotifyTests: XCTestCase {
    func testGetCurrentTrack() {
        let expectedTrack = TestTrack.LetTheFlamesBegin._backingTrack
        let (session, _, _) = SpotijackSessionManager.makeStandardApplications()

        XCTAssertNotNil(session.currentTrack)
        XCTAssertEqual(session.currentTrack, expectedTrack)
    }

    func testChangeTrackNotifiesDelegate() {
        let expectedTrack = TestTrack.FakeHappy._backingTrack
        var receivedTrack: Track?

        let (session, spotify, _) = SpotijackSessionManager.makeStandardApplications()
        let obs = session.notificationCenter.addObserver(forType: TrackDidChange.self,
                                                         object: session,
                                                         queue: .main,
                                                         using: { noti in
                                                            receivedTrack = noti.newTrack })

        spotify.nextTrack()

        // Simulate a polling
        session.pollSpotify()
        session.pollAudioHijackPro()

        XCTAssertNotNil(receivedTrack)
        XCTAssertEqual(receivedTrack, expectedTrack)
    }
}
