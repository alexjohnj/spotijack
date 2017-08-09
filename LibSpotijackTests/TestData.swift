//
//  TestData.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 20/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

internal protocol TestTrack {
    static var uri: String { get }
    static var name: String { get }
    static var artist: String { get }
    static var album: String { get }
}

internal struct LetTheFlamesBegin: TestTrack {
    static let uri: String = "spotify:track:2myJNvcL71V5IZ1N2NW29O"
    static let name: String = "Let The Flames Begin"
    static let artist: String = "Paramore"
    static let album: String = "RIOT!"
}

internal struct FakeHappy: TestTrack {
    static let uri: String = "spotify:track:6t44iU80A0h8WQ7vc4OoRj"
    static let name: String = "Fake Happy"
    static let artist: String = "Paramore"
    static let album: String = "After Laughter"
}

// The last track on the album.
internal struct BabesNeverDieOutro: TestTrack {
    static let uri: String = "spotify:track:3itTGCLe81VNhG9Jo2wHxP"
    static let name: String = "Outro"
    static let artist: String = "Honeyblood"
    static let album: String = "Babes Never Die"
}
