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
    public let starred: Bool
    public let popularity: Int
    public let id: String
    public let name: String
    public let artworkURL: String
    public let albumArtist: String
    public let spotifyURL: String

    public init(from track: SpotifyTrack) {
        self.artist = track.artist!
        self.album = track.album!
        self.discNumber = track.discNumber!
        self.duration = track.duration!
        self.trackNumber = track.trackNumber!
        self.starred = track.starred!
        self.popularity = track.popularity!
        self.id = track.id!()
        self.name = track.name!
        self.artworkURL = track.artworkUrl!
        self.albumArtist = track.albumArtist!
        self.spotifyURL = track.spotifyUrl!
    }
}

extension StaticSpotifyTrack: Equatable {
    public static func ==(lhs: StaticSpotifyTrack, rhs: StaticSpotifyTrack) -> Bool {
        return lhs.id == rhs.id
    }
}
