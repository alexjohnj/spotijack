//
//  TestData.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 20/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

extension StaticSpotifyTrack {
    init(artist: String, album: String, discNumber: Int, duration: Int, trackNumber: Int, starred: Bool,
         popularity: Int, id: String, name: String, artworkURL: String, albumArtist: String, spotifyURL: String) {
        self.artist = artist
        self.album = album
        self.discNumber = discNumber
        self.duration = duration
        self.trackNumber = trackNumber
        self.starred = starred
        self.popularity = popularity
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
        self.albumArtist = albumArtist
        self.spotifyURL = spotifyURL
    }
}

internal enum TestTrack {
    static let LetTheFlamesBegin = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Paramore",
        album: "RIOT",
        discNumber: 1,
        duration: 198,
        trackNumber: 6,
        starred: false,
        popularity: 100,
        id: "spotify:track:2myJNvcL71V5IZ1N2NW29O",
        name: "Let The Flames Begin",
        artworkURL: "https://spotify.com", // FAKE
        albumArtist: "Paramore",
        spotifyURL: "https://open.spotify.com/track/2myJNvcL71V5IZ1N2NW29O"))

    static let FakeHappy = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Paramore",
        album: "Hard Times",
        discNumber: 1,
        duration: 234,
        trackNumber: 6,
        starred: false,
        popularity: 50,
        id: "spotify:track:6t44iU80A0h8WQ7vc4OoRj",
        name: "Fake Happy",
        artworkURL: "https://spotify.com", // FAKE
        albumArtist: "Paramore",
        spotifyURL: "https://open.spotify.com/track/6t44iU80A0h8WQ7vc4OoRj"))

    static let BabesNeverDieOutro = MockSpotifyTrack(backingTrack: StaticSpotifyTrack(
        artist: "Honeyblood",
        album: "Babes Never Die",
        discNumber: 1,
        duration: 73,
        trackNumber: 12,
        starred: true,
        popularity: 100,
        id: "spotify:track:3itTGCLe81VNhG9Jo2wHxP",
        name: "Outro",
        artworkURL: "https://spotify.com", // FAKE
        albumArtist: "Honeyblood",
        spotifyURL: "https://open.spotify.com/track/3itTGCLe81VNhG9Jo2wHxP"))
}
