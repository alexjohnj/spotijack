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
    static let LetTheFlamesBegin = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Paramore",
        album: "RIOT",
        discNumber: 1,
        duration: 198,
        trackNumber: 6,
        id: "spotify:track:2myJNvcL71V5IZ1N2NW29O",
        name: "Let The Flames Begin",
        albumArtist: "Paramore"
        )
    )

    static let FakeHappy = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Paramore",
        album: "Hard Times",
        discNumber: 1,
        duration: 234,
        trackNumber: 6,
        id: "spotify:track:6t44iU80A0h8WQ7vc4OoRj",
        name: "Fake Happy",
        albumArtist: "Paramore"
        )
    )

    static let BabesNeverDieOutro = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Honeyblood",
        album: "Babes Never Die",
        discNumber: 1,
        duration: 73,
        trackNumber: 12,
        id: "spotify:track:3itTGCLe81VNhG9Jo2wHxP",
        name: "Outro",
        albumArtist: "Honeyblood"
        )
    )
}
