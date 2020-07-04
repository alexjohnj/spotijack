//
//  RecordingEngine.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

protocol RecordingEngine {

    /// Instructs the engine to start a new recording using a given configuration.
    ///
    /// This method must be synchronous---by the time it returns the engine must be capturing audio data. Calling this
    /// method while a recording is in progress is allowed and should start a new recording.
    ///
    func startNewRecording(using configuration: RecordingConfiguration) throws

    /// Instructs the engine to end a recording if one is in progress.
    func stopRecording()
}
