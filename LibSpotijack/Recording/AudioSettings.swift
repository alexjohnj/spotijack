//
//  AudioSettings.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

public struct AudioSettings: Hashable {

    // MARK: - Nested Types

    public enum Encoding {
        case alac
    }

    public enum Container {
        case m4a
    }

    // MARK: - Public Properties

    public var encoding: Encoding
    public var container: Container

    // MARK: - Initializers

    public init(encoding: Encoding, container: Container) {
        self.encoding = encoding
        self.container = container
    }
}

// MARK: - Core Audio Integration

import AVFoundation

extension AudioSettings.Encoding {
    var formatID: AudioFormatID {
        switch self {
        case .alac:
            return kAudioFormatAppleLossless
        }
    }
}

extension AudioSettings.Container {
    var fileType: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        }
    }
}
