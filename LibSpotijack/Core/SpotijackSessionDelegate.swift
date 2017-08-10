//
//  SpotijackSessionDelegate.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 10/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

/// `SpotijackSessionDelegate` provides a set of methods through which a `SpotijackSession` instance can communicate
/// with its manager.
internal protocol SpotijackSessionDelegate: class {
    /// Called when the active Spotify track changes
    ///
    /// - parameter session : The session whose Spotify instance changed track.
    /// - parameter track : The new track playing in Spotify.
    func session(_ session: SpotijackSession, didChangeToTrack track: StaticSpotifyTrack?)

    /// Called when the Spotijack session is muted or unmuted.
    ///
    /// - parameter session : The session whose Spotijack session changed mute state.
    /// - parameter isMuted : The new mute state of the Spotijack session.
    func session(_ session: SpotijackSession, didMute isMuted: Bool)

    /// Called when the Spotijack session starts or ends recording.
    ///
    /// - parameter session : The session whose Spotijack session changed recording state.
    /// - parameter isRecording : The new recording state of the Spotijack session.
    func session(_ session: SpotijackSession, didChangeRecordingState isRecording: Bool)

    /// Called when an error occurs.
    ///
    /// - parameter session : The session that encountered an error.
    /// - parameter error : The error.
    func session(_ session: SpotijackSession, didEncounterError error: Error)

    /// Called when Spotify's playback queue is exhausted.
    ///
    /// - parameter session : The session whose Spotify instance's queue was exhausted.
    func sessionDidReachEndOfPlaybackQueue(_ session: SpotijackSession)
}
