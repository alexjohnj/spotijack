//
//  RecordingProcessor.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 05/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

protocol RecordingProcessing {

    /// Asks the processor to start processing a saved recording.
    ///
    /// - Parameters:
    ///   - recordingURL: The location of the recording to process
    ///   - completion: A block to execute when the processor finishes. The processor should provide the final URL
    ///     of the processed recording in the completion handler.
    ///
    func processCompletedRecording(at recordingURL: URL, completion: ((Result<URL, Error>) -> Void))
}
