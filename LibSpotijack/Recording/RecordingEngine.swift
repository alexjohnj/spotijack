//
//  RecordingEngine.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

public protocol RecordingEngine {
    func startNewRecording(using configuration: RecordingConfiguration) throws
    func stopRecording()
}
