//
//  MockRecorder.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

final class MockRecordingEngine: RecordingEngine {

    var startNewRecordingInvocations = [RecordingConfiguration]()
    var startNewRecordingInvocationCount: Int { startNewRecordingInvocations.count }
    var startNewRecordingInvoked: Bool { !startNewRecordingInvocations.isEmpty }

    func startNewRecording(using configuration: RecordingConfiguration) throws {
        startNewRecordingInvocations.append(configuration)
    }

    var stopRecordingInvocationCount = 0
    var stopRecordingInvoked: Bool { stopRecordingInvocationCount > 0 }
    func stopRecording() {
        stopRecordingInvocationCount += 1
    }
}
