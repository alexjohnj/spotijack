//
//  MockMusicPlayer.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack
import Combine

final class MockMusicapp: MusicApplication {

    static let name = "MockMusicPlayer"

    static let bundleID = "fake.org.alexj.MockMusicPlayer"

    static func launch(completion: @escaping (Result<MusicApplication, Error>) -> Void) {
    }

    var playerPosition: Double = 0

    var playerState: PlayerState = .stopped

    var currentTrack: Track?

    var currentTrackID: String?

    var trackIDSubject = PassthroughSubject<String?, Never>()
    var trackIDPublisher: AnyPublisher<String?, Never> { trackIDSubject.eraseToAnyPublisher() }

    var playInvocationCount = 0
    var playInvoked: Bool { playInvocationCount > 0 }
    func play() {
        playInvocationCount += 1
    }

    var pauseInvocationCount = 0
    var pauseInvoked: Bool { pauseInvocationCount > 0 }
    func pause() {
        pauseInvocationCount += 1
    }

    var setRepeatEnabledInvocations = [Bool]()
    var setRepeatEnabledInvoked: Bool { !setRepeatEnabledInvocations.isEmpty }
    var setRepeatEnabledInvocationCount: Int { setRepeatEnabledInvocations.count }
    func setRepeatEnabled(_ enableRepeat: Bool) {
        setRepeatEnabledInvocations.append(enableRepeat)
    }

    var setShuffleEnabledInvocations = [Bool]()
    var setShuffleEnabledInvoked: Bool { !setShuffleEnabledInvocations.isEmpty }
    var setShuffleEnabledInvocationCount: Int { setShuffleEnabledInvocations.count }
    func setShuffleEnabled(_ enableShuffle: Bool) {
        setShuffleEnabledInvocations.append(enableShuffle)
    }
}
