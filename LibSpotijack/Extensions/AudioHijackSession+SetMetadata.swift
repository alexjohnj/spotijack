//
//  AudioHijackSession+SetMetadata.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 23/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

extension AudioHijackSession {
    internal func setMetadata(from track: StaticSpotifyTrack) {
        setTitleTag!(track.name)
        setArtistTag!(track.artist)
        setAlbumArtistTag!(track.albumArtist)
        setAlbumTag!(track.album)
        setTrackNumberTag!(String(describing: track.trackNumber))
        setDiscNumberTag!(String(describing: track.discNumber))
    }
}
