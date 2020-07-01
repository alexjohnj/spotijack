//
//  StaticSpotifyTrack.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 22/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

public struct Track: Hashable, Equatable, Identifiable {
    public let id: String

    public var artist: String
    public var album: String
    public var discNumber: Int
    public var duration: Int
    public var trackNumber: Int
    public var name: String
    public var albumArtist: String
}

extension Track {
    init(from track: SpotifyTrackSBObject) {
        self.id = track.id!()

        self.artist = track.artist!
        self.album = track.album!
        self.discNumber = track.discNumber!
        self.duration = track.duration!
        self.trackNumber = track.trackNumber!
        self.name = track.name!
        self.albumArtist = track.albumArtist!
    }
}
