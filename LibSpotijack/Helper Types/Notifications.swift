//
//  Notifications.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 12/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import TypedNotification

public extension Namespaced {
    static var namespace: String { return "org.alexj.LibSpotijack" }
}

/// Posted when the mute state of Spotify changes.
public struct MuteStateDidChange: TypedNotification {
    public let sender: SpotijackSessionManager
    public let newMuteState: Bool
}

/// Posted when an error occurs outside of a throwing a function.
/// For example, accessing the muted state of Spotify when a
/// scripting interface can't be obtained.
public struct DidEncounterError: TypedNotification {
    public let sender: SpotijackSessionManager
    public let error: Error
}

/// Posted when the recording state of the Spotijack session changes.
public struct RecordingStateDidChange: TypedNotification {
    public let sender: SpotijackSessionManager
    public let isRecording: Bool
}

/// Posted when the currently playing track in Spotify changes. The
/// attached track can be `nil` if no more tracks are playing.
public struct TrackDidChange: TypedNotification {
    public let sender: SpotijackSessionManager
    public let newTrack: StaticSpotifyTrack?
}

/// Posted when there are no more tracks to play in Spotify and Spotijacking has
/// been stopped.
public struct DidReachEndOfPlaybackQueue: TypedNotification {
    public let sender: SpotijackSessionManager
}
