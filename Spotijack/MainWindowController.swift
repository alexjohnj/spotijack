//
//  MainWindowController.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import AppKit
import Combine
import AVFoundation

import LibSpotijack

internal class MainWindowController: NSWindowController {

    // MARK: Private Properties

    private let sessionCoordinator: SessionCoordinator
    private let musicApp: MusicApplication
    private let testDevice = AVCaptureDevice(uniqueID: "com.rogueamoeba.Loopback:FA961DC0-CDBE-4CE4-A609-EA5BD676F205")!

    private var cancellationBag: [AnyCancellable] = []

    // MARK: - Outlets

    @IBOutlet private weak var statusField: NSTextField!
    @IBOutlet private weak var artistAlbumField: NSTextField!
    @IBOutlet private weak var spotijackButton: NSButton!

    // MARK: - Initializers

    init(musicApp: MusicApplication, sessionCoordinator: SessionCoordinator) {
        self.musicApp = musicApp
        self.sessionCoordinator = sessionCoordinator
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("\(Self.self) does not implement \(#function)")
    }

    // MARK: Window Lifecycle

    override var windowNibName: NSNib.Name? {
        "MainWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        sessionCoordinator.$isRecording
            .sink { [unowned self] isRecording in
                if isRecording {
                    spotijackButton.title = NSLocalizedString("Recording", comment: "")
                    spotijackButton.state = .on
                } else {
                    spotijackButton.title = NSLocalizedString("Record", comment: "")
                    spotijackButton.state = .off
                }
            }
            .store(in: &cancellationBag)

        musicApp.trackIDPublisher
            .map { [musicApp] _ in musicApp.currentTrack }
            .sink { [unowned self] track in
                if let track = track {
                    statusField.stringValue = track.name
                    artistAlbumField.stringValue = "\(track.artist) — \(track.album)"
                } else {
                    statusField.stringValue = NSLocalizedString("Ready to Record", comment: "")
                    artistAlbumField.stringValue = ""
                }
            }
            .store(in: &cancellationBag)
    }
}

// MARK: - UI Actions
extension MainWindowController {
    @IBAction func spotijackButtonClicked(_ sender: NSButton) {
        if sessionCoordinator.isRecording {
            sessionCoordinator.stopRecording()
        } else {
            do {
                try sessionCoordinator.startRecording(from: testDevice, using: SessionCoordinator.Configuration())
            } catch {
                _ = presentError(error)
            }
        }
    }
}

// MARK: Responder Chain Error Interception

extension MainWindowController {
    override open func presentError(_ error: Error) -> Bool {
        guard error is SpotijackError.SpotijackSessionNotFound else {
            return super.presentError(error)
        }

        do {
            try SpotijackSessionCreator.createSpotijackSession()
            return true
        } catch {
            return super.presentError(error)
        }
    }
}
