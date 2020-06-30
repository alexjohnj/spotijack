//
//  AudioRecorder.Configuration.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 30/06/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import AVFoundation

extension AudioRecorder {
    public struct Configuration: Equatable {
        var outputFile: URL
        var fileFormat: AudioFileFormat
        var encoding: AudioEncoding
    }

    enum AudioFileFormat: CaseIterable {
        case m4a

        var defaultFileExtension: String {
            switch self {
            case .m4a:
                return "m4a"
            }
        }

        var fileType: AVFileType {
            switch self {
            case .m4a:
                return .m4a
            }
        }
    }

    enum AudioEncoding: CaseIterable {
        case alac

        var formatID: AudioFormatID {
            switch self {
            case .alac:
                return kAudioFormatAppleLossless
            }
        }
    }
}
