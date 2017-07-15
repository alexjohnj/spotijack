//
//  LibSpotijackTests.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 13/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import XCTest
@testable import LibSpotijack

let spotifyBundle = "com.spotify.client"
let audioHijackBundle = "com.rogueamoeba.AudioHijackPro2"

class LibSpotijackTests: XCTestCase {
    override func setUp() {
        super.setUp()

        killAllApplications()
        let launchExpect = expectation(description: "Waiting to establish session.")
        SpotijackSessionManager.establishSession { sessionResult in
            guard case .ok = sessionResult else {
                XCTFail()
                return
            }
            launchExpect.fulfill()
        }

        wait(for: [launchExpect], timeout: 5.0)
    }

    override func tearDown() {
        super.tearDown()

        killAllApplications()
    }

    func killAllApplications() {
        NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundle).first?.forceTerminate()
        NSRunningApplication.runningApplications(withBundleIdentifier: audioHijackBundle).first?.forceTerminate()
    }
}
