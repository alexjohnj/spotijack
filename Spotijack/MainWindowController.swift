//
//  MainWindowController.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import LibSpotijack
import TypedNotification

class MainWindowController: NSWindowController {
    //MARK: Interface Builder Outlets
    @IBOutlet weak var statusField: NSTextField!
    @IBOutlet weak var artistField: NSTextField!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var muteButton: NSButton!

    //MARK: Notification Observer Tokens
    private var _muteStateDidChangeObserver: NotificationObserver? = nil
    private var _didEncounterErrorObserver: NotificationObserver? = nil
    private var _recordingStateDidChangeObserver: NotificationObserver? = nil
    private var _trackDidChangeObserver: NotificationObserver? = nil

    //MARK: Window Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()

        registerForSpotijackNotifications()
    }
}

//MARK: UI Actions
extension MainWindowController {
    @IBAction func recordButtonClicked(_ sender: NSButton) {
    }

    @IBAction func muteButtonClicked(_ sender: NSButton) {
    }
}

//MARK: Notification Handling
extension MainWindowController {
    private func muteStateDidChange(noti: MuteStateDidChange) {
    }

    private func recordingStateDidChange(noti: RecordingStateDidChange) {
    }

    private func trackDidChange(noti: TrackDidChange) {
    }

    private func didEncounterError(noti: DidEncounterError) {
    }

    /// Registers the window controller for notifications posted by
    /// SpotijackSessionManager
    private func registerForSpotijackNotifications() {
        let sessionManager = SpotijackSessionManager.shared
        let notificationCenter = sessionManager.notiCenter

        _muteStateDidChangeObserver = notificationCenter.addObserver(
            forType: MuteStateDidChange.self,
            object: sessionManager,
            queue: .main,
            using: { [weak self] noti in self?.muteStateDidChange(noti: noti) })

        _didEncounterErrorObserver = notificationCenter.addObserver(
            forType: DidEncounterError.self,
            object: sessionManager,
            queue: .main,
            using: { [weak self] noti in self?.didEncounterError(noti: noti) })

        _trackDidChangeObserver = notificationCenter.addObserver(
            forType: TrackDidChange.self,
            object: sessionManager,
            queue: .main,
            using: { [weak self] noti in self?.trackDidChange(noti: noti) })

        _recordingStateDidChangeObserver = notificationCenter.addObserver(
            forType: RecordingStateDidChange.self,
            object: sessionManager,
            queue: .main,
            using: { [weak self] noti in self?.recordingStateDidChange(noti: noti) })
    }
}
