//
//  SpotijackSessionExtensions.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

extension SpotijackSessionManager {
    /// Makes standard mock Spotify and AHP applications and configures a new SpotijackSession to use them.
    // swiftlint:disable:next large_tuple
    typealias StandardApplications = (SpotijackSessionManager, MockSpotifyApplication, MockAudioHijackApplication)
    static func makeStandardApplications() -> StandardApplications {
        let spotify = MockSpotifyApplication.makeStandardApplication()
        let ahp = MockAudioHijackApplication.makeStandardApplication()
        let session = SpotijackSessionManager(spotifyBridge: spotify, audioHijackBridge: ahp)

        return (session, spotify, ahp)
    }
}
