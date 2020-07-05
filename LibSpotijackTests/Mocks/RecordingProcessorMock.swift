// swiftlint:disable all
//
//  RecordingProcessorMock.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 05/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
@testable import LibSpotijack

final class MockRecordingProcessor: RecordingProcessing {

    var processRecordingInvocations: [(recordingURL: URL, configuration: SessionCoordinator.Configuration, completion: ((Result<URL, Error>) -> Void)?)] = []
    var processRecordingInvoked: Bool { !processRecordingInvocations.isEmpty }

    func processRecording(at recordingURL: URL, recordedWith configuration: SessionCoordinator.Configuration, completion: ((Result<URL, Error>) -> Void)?) {
        processRecordingInvocations.append((recordingURL, configuration, completion))
    }
}
