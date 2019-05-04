//
//  StaticSpotifyTrack.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 22/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

/// A value type reimplementation of `SpotifyTrack`. The advantage of this type
/// compared to the original is that the track id is not tied to the currently
/// playing track. The id is the id of whatever track is playing during
/// initialisation.
public struct StaticSpotifyTrack {
    public let artist: String
    public let album: String
    public let discNumber: Int
    public let duration: Int
    public let trackNumber: Int
    public let id: String
    public let name: String
    public let albumArtist: String
}

extension StaticSpotifyTrack {
    public init(from track: SpotifyTrack) {
        // Load all the track's properties to avoid multiple RPC calls for each property
        // swiftlint:disable:next force_cast
        let loadedTrack = track.get() as! SpotifyTrack
        self.artist = loadedTrack.artist!
        self.album = loadedTrack.album!
        self.discNumber = loadedTrack.discNumber!
        self.duration = loadedTrack.duration!
        self.trackNumber = loadedTrack.trackNumber!
        self.id = loadedTrack.id!()
        self.name = loadedTrack.name!
        self.albumArtist = loadedTrack.albumArtist!
    }
}

extension StaticSpotifyTrack: Equatable {
    public static func == (lhs: StaticSpotifyTrack, rhs: StaticSpotifyTrack) -> Bool {
        return lhs.id == rhs.id
    }
}
