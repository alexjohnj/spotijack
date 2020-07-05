//
//  MockRecorder.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

final class MockRecordingEngine: RecordingEngine {

    weak var delegate: RecordingEngineDelegate?

    var startNewRecordingInvocations = [RecordingConfiguration]()
    var startNewRecordingInvocationCount: Int { startNewRecordingInvocations.count }
    var startNewRecordingInvoked: Bool { !startNewRecordingInvocations.isEmpty }

    func startNewRecording(using configuration: RecordingConfiguration) throws {
        startNewRecordingInvocations.append(configuration)
    }

    var stopRecordingInvocations: [(() -> Void)?] = []
    var stopRecordingInvocationCount: Int { stopRecordingInvocations.count }
    var stopRecordingInvoked: Bool { !stopRecordingInvocations.isEmpty }
    func stopRecording(completionHandler: (() -> Void)?) {
        stopRecordingInvocations.append(completionHandler)
    }
}
