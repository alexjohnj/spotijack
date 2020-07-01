//
//  MusicApplication.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import Combine

public protocol MusicApplication {

    static var name: String { get }
    static var bundleID: String { get }

    static func launch(completion: @escaping (Result<MusicApplication, Error>) -> Void)

    var playerPosition: Double { get set }
    var playerState: PlayerState { get }

    /// The currently playing track or `nil` if there is no track playing.
    var currentTrack: Track? { get }

    /// The ID of the currently playing track or `nil` if there is no track playing.
    ///
    /// Conforming types should implement this property as an optimisation over the `currentTrack` property
    /// to avoid transferring too much data over XPC.
    ///
    var currentTrackID: String? { get }

    /// A publisher of the current track ID.
    ///
    /// Conforming types should publish the current track ID when it changes on the main queue.
    ///
    var trackIDPublisher: AnyPublisher<String?, Never> { get }

    func play()
    func pause()
    func setRepeatEnabled(_ enableRepeat: Bool)
    func setShuffleEnabled(_ enableShuffle: Bool)
}
