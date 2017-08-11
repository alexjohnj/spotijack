//
//  SpotijackSessionSpotijackingTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 11/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
import Foundation
@testable import LibSpotijack

internal class SpotijackSessionSpotijackingTests: XCTestCase {
    func testStartStopPolling() {
        let (session, _, _) = SpotijackSession.makeStandardApplications()

        session.startPolling(every: 1.0)
        XCTAssertNotNil(session._applicationPollingTimer)
        XCTAssertTrue(session.isPolling)

        session.stopPolling()
        XCTAssertFalse(session.isPolling)
        XCTAssertNil(session._applicationPollingTimer)
    }

    func testStartPollingRespectsInterval() {
        let expectedInterval: TimeInterval = 1.0
        let (session, _, _) = SpotijackSession.makeStandardApplications()

        session.startPolling(every: expectedInterval)
        XCTAssertEqual(session._applicationPollingTimer?.timeInterval, expectedInterval)
    }
}
