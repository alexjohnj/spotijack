//
//  RecordingEngine.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

protocol RecordingEngine: AnyObject {

    var delegate: RecordingEngineDelegate? { get set }

    /// Instructs the engine to start a new recording using a given configuration.
    ///
    /// This method must be synchronous---by the time it returns the engine must be capturing audio data. Calling this
    /// method while a recording is in progress is allowed and should start a new recording.
    ///
    func startNewRecording(using configuration: RecordingConfiguration) throws

    /// Instructs the recording engine to stop the current recording and free any recording resources.
    ///
    /// - Parameter completionHandler: A block to execute when the receiver has finished recording and all resources
    /// are freed. The completion handler can be called from any thread.
    ///
    func stopRecording(completionHandler: (() -> Void)?)
}

protocol RecordingEngineDelegate: AnyObject {

    /// Notifies the delegate that recording has finished. This can be called from any thread.
    func recordingEngine(_ recordingEngine: RecordingEngine, didFinishRecordingTo fileURL: URL, withError error: Error?)
}
