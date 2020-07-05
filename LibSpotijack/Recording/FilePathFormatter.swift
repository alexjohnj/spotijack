//
//  FileNameFormatter.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

public struct FilePathFormatter: Hashable {

    public init() { }

    func filePath(for track: Track, recordedWith audioSettings: AudioSettings) throws -> URL {
        let outputDirectory = try FileManager.default
            .url(for: .musicDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Spotijack", isDirectory: true)
            .appendingPathComponent(track.artist)
            .appendingPathComponent(track.album)

        let fileBaseName = "\(track.trackNumber) - \(track.name)"
        return outputDirectory
            .appendingPathComponent(fileBaseName, isDirectory: false)
            .appendingPathExtension(audioSettings.container.fileExtension)
    }
}
