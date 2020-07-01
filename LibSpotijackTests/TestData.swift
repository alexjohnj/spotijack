//
//  TestData.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 20/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

internal enum TestTrack {
    static let LetTheFlamesBegin = MockSpotifyTrack(backingTrack: Track(
        id: "spotify:track:2myJNvcL71V5IZ1N2NW29O",
        artist: "Paramore",
        album: "RIOT",
        discNumber: 1,
        duration: 198,
        trackNumber: 6,
        name: "Let The Flames Begin",
        albumArtist: "Paramore"
        )
    )

    static let FakeHappy = MockSpotifyTrack(backingTrack: Track(
        id: "spotify:track:6t44iU80A0h8WQ7vc4OoRj",
        artist: "Paramore",
        album: "Hard Times",
        discNumber: 1,
        duration: 234,
        trackNumber: 6,
        name: "Fake Happy",
        albumArtist: "Paramore"
        )
    )

    static let BabesNeverDieOutro = MockSpotifyTrack(backingTrack: Track(
        id: "spotify:track:3itTGCLe81VNhG9Jo2wHxP",
        artist: "Honeyblood",
        album: "Babes Never Die",
        discNumber: 1,
        duration: 73,
        trackNumber: 12,
        name: "Outro",
        albumArtist: "Honeyblood"
        )
    )
}
