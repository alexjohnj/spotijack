//
//  SpotifyApplication.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import Combine
import os.log
import ScriptingBridge

private let log = OSLog(subsystem: "org.alexj.Spotijack", category: "SpotifyApplication")
private let kSpotifyPollingInterval: TimeInterval = 0.1

public final class SpotifyApplication: MusicApplication {

    // MARK: - Public Properties

    public static let name = "Spotify"
    public static let bundleID = "com.spotify.client"

    public var playerPosition: Double {
        get {
            spotifyBridge.playerPosition!
        }

        set {
            spotifyBridge.setPlayerPosition!(newValue)
        }
    }

    public var playerState: PlayerState {
        PlayerState(spotifyBridge.playerState!)
    }

    public var currentTrack: Track? {
        spotifyBridge.currentTrack.map(Track.init(from:))
    }

    public var currentTrackID: String? {
        spotifyBridge.currentTrack?.id?()
    }

    public let trackIDPublisher: AnyPublisher<String?, Never>

    // MARK: - Private Properties

    private let spotifyBridge: SpotifySBApplication

    // MARK: - Initializers

    private init(spotifyBridge: SpotifySBApplication) {
        self.spotifyBridge = spotifyBridge
        self.trackIDPublisher = Timer.publish(every: kSpotifyPollingInterval, on: .main, in: .default)
            .autoconnect()
            .map { _ in spotifyBridge.currentTrack?.id?() }
            .removeDuplicates()
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    public static func launch(completion: @escaping (Result<MusicApplication, Error>) -> Void) {
        os_log(.debug, log: log, "Launching Spotify")

        let completeWithResult: (Result<MusicApplication, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID) else {
            completeWithResult(.failure(SpotijackError.CantStartApplication(appName: Self.name)))
            return
        }

        let openConfig = NSWorkspace.OpenConfiguration()
        openConfig.activates = false
        openConfig.hides = true

        NSWorkspace.shared.openApplication(at: applicationURL, configuration: openConfig) { app, error in
            guard let app = app else {
                os_log(.error, log: log, "Failed to open Spotify application with error %{public}@",
                       error.map(String.init(describing:)) ?? "NO_ERROR")
                completeWithResult(.failure(SpotijackError.ApplicationNotLaunched(appName: Self.name)))
                return
            }

            guard let spotifyBridge = SBApplication(processIdentifier: app.processIdentifier) else {
                os_log(.error, log: log, "Could not create a scripting bridge to Spotify")
                completeWithResult(.failure(SpotijackError.NoScriptingInterface(appName: Self.name)))
                return
            }

            os_log(.info, log: log, "Spotify launched")
            let spotifyApp = SpotifyApplication(spotifyBridge: spotifyBridge)
            completeWithResult(.success(spotifyApp))
        }
    }

    public func play() {
        spotifyBridge.play!()
    }

    public func pause() {
        spotifyBridge.pause!()
    }

    public func setRepeatEnabled(_ enableRepeat: Bool) {
        spotifyBridge.setRepeating!(enableRepeat)
    }

    public func setShuffleEnabled(_ enableShuffle: Bool) {
        spotifyBridge.setShuffling!(enableShuffle)
    }
}

// MARK: - PlayerState + Spotify Bridge

private extension PlayerState {
    init(_ spotifyState: SpotifyEPlS) {
        switch spotifyState {
        case .stopped:
            self = .stopped
        case .playing:
            self = .playing
        case .paused:
            self = .paused
        }
    }
}
