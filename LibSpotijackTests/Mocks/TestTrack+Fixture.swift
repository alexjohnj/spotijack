//
//  TestTrack+Fixture.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

extension Track {
    static func fixture(
        id: String = "DEADBEEF",
        artist: String = "Paramore",
        album: String = "After Laughter",
        discNumber: Int = 1,
        duration: Int = 183,
        trackNumber: Int = 1,
        name: String = "Hard Times",
        albumArtist: String = "Paramore"
    ) -> Track {
        Track(
            id: id,
            artist: artist,
            album: album,
            discNumber: discNumber,
            duration: duration,
            trackNumber: trackNumber,
            name: name,
            albumArtist: albumArtist
        )
    }
}
