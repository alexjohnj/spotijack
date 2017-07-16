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
        let spotifyKillExpect = expectation(description: "Waiting for Spotify to terminate.")
        let audioHijackKillExpect = expectation(description: "Waiting for AHP to terminate.")
        var spotifyObserver: NSKeyValueObservation? = nil
        var audioHijackObserver: NSKeyValueObservation? = nil

        if let spotify = NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundle).first {
            spotifyObserver = spotify.observe(\.isTerminated) { (observer, _) in
                if observer.isTerminated == true {
                    spotifyKillExpect.fulfill()
                }
            }

            spotify.forceTerminate()
        } else {
            spotifyKillExpect.fulfill()
        }

        if let audioHijack = NSRunningApplication.runningApplications(withBundleIdentifier: audioHijackBundle).first {
            audioHijackObserver = audioHijack.observe(\.isTerminated) { (observer, _) in
                if observer.isTerminated == true {
                    audioHijackKillExpect.fulfill()
                }
            }

            audioHijack.forceTerminate()
        } else {
            audioHijackKillExpect.fulfill()
        }

        wait(for: [audioHijackKillExpect, spotifyKillExpect], timeout: 10.0)
    }
}
    }
}
