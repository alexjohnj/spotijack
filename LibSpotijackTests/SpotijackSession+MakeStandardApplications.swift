//
//  SpotijackSession+MakeStandardApplications.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

extension SpotijackSession {
    /// Makes standard mock Spotify and AHP applications and configures a new SpotijackSession to use them.
    // swiftlint:disable:next large_tuple
    static func makeStandardApplications() -> (SpotijackSession, MockSpotifyApplication, MockAudioHijackApplication) {
        let spotify = MockSpotifyApplication.makeStandardApplication()
        let ahp = MockAudioHijackApplication.makeStandardApplication()
        let session = SpotijackSession(spotifyBridge: spotify, audioHijackBridge: ahp)

        return (session, spotify, ahp)
    }
}
