//
//  MockSpotifyTrack.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

internal class MockSpotifyTrack: NSObject {
    // A StaticSpotifyTrack that this track represents
    var _backingTrack: StaticSpotifyTrack

    init(backingTrack: StaticSpotifyTrack) {
        _backingTrack = backingTrack

        super.init()
    }
}

// MARK: - SpotifyTrack Protocol Conformance
extension MockSpotifyTrack: SpotifyTrack {
    func get() -> Any! {
        fatalError("Not implemented")
    }

    // MARK: Implemented
    var artist: String { return _backingTrack.artist }
    var album: String { return _backingTrack.album }
    var discNumber: Int { return _backingTrack.discNumber }
    var duration: Int { return _backingTrack.duration }
    var trackCount: Int { return _backingTrack.trackNumber }
    var name: String { return _backingTrack.name }
    var artworkUrl: String { return _backingTrack.artworkURL }
    var albumArtist: String { return _backingTrack.albumArtist }
    var spotifyUrl: String { return _backingTrack.spotifyURL }
    var starred: Bool { return _backingTrack.starred }
    var popularity: Int { return _backingTrack.popularity }

    func id() -> String {
        return _backingTrack.id
    }

    // MARK: Not Implemented
    var playedCount: Int { fatalError("Not implemented") }
    var artwork: NSImage { fatalError("Not implemented") }

    func setSpotifyUrl(_ spotifyUrl: String!) {
        fatalError("Not implemented")
    }
}
