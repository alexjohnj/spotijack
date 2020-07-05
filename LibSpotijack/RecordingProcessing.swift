//
//  RecordingProcessor.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 05/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

/// A type that can post-process recordings for a `SessionCoordinator`.
protocol RecordingProcessing: AnyObject {

    /// Asks the processor to start processing a saved recording. The session can call this from any queue.
    ///
    /// - Parameters:
    ///   - recordingURL: The location of the recording to process
    ///   - completion: A block to execute when the processor finishes. The processor should provide the final URL
    ///     of the processed recording in the completion handler.
    ///
    func enqueueRecording(at recordingURL: URL, forTrack track: Track, recordedWith configuration: SessionCoordinator.Configuration, completion: ((Result<URL, Error>) -> Void)?)
}

final class RecordingProcessor: RecordingProcessing {

    // MARK: - Private Properties

    private let workerQueue = DispatchQueue(label: "org.alexj.Spotijack.RecordingProcessorQueue", qos: .utility)
    private let fileManager: FileManager

    // MARK: - Initializers

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func enqueueRecording(at recordingURL: URL, forTrack track: Track, recordedWith configuration: SessionCoordinator.Configuration, completion: ((Result<URL, Error>) -> Void)?) {
        let result = Result<URL, Error> {
            let desiredURL = try configuration.fileNameFormatter.filePath(for: track, recordedWith: configuration.audioSettings)
            try createParentDirectory(for: desiredURL)
            let finalURL = try moveFileResolvingConflicts(from: recordingURL, to: desiredURL)
            return finalURL
        }

        completion?(result)
    }

    // MARK: - Private Methods

    private func createParentDirectory(for destinationURL: URL) throws {
        let parent = destinationURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
        } catch CocoaError.fileWriteFileExists {
            return
        } catch {
            throw error
        }
    }

    private func moveFileResolvingConflicts(from sourceURL: URL, to destination: URL) throws -> URL {
        var isMoved = false
        var attempt = 0
        var adjustedDestination = destination

        while !isMoved {
            do {
                try fileManager.moveItem(at: sourceURL, to: adjustedDestination)
                isMoved = true
            } catch CocoaError.fileWriteFileExists {
                attempt += 1
                adjustedDestination = destination.appendingConflictNumber(attempt)
            } catch {
                throw error
            }
        }

        return adjustedDestination
    }
}

// MARK: - File Management Helpers

private extension URL {
    func appendingConflictNumber(_ number: Int) -> URL {
        var copy = self
        let pathExtension = copy.pathExtension

        copy.deletePathExtension()
        let newFileName = copy.lastPathComponent.appending(" (\(number))")
        copy.deleteLastPathComponent()
        copy.appendPathComponent(newFileName)
        copy.appendPathExtension(pathExtension)

        return copy
    }
}
