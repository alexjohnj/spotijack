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

        // Start polling and update the UI
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .ok(let session):
                session.startPolling(every: 0.1) //TODO: Use configurable polling interval
                self?.refreshUI()
            case .fail(let error):
                self?.presentError(error)
            }
        }
    }
}

//MARK: UI Actions
extension MainWindowController {
    @IBAction func recordButtonClicked(_ sender: NSButton) {
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .fail(let error):
                self?.presentError(error)
            case .ok(let session):
                if session.isSpotijacking {
                    session.stopSpotijackSession()
                } else {
                    do {
                        try session.startSpotijackSession(config: Preferences.shared.recordingConfiguration)
                    } catch (let error) {
                        self?.presentError(error)
                    }
                }
            }
        }
    }

    @IBAction func muteButtonClicked(_ sender: NSButton) {
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .fail(let error):
                self?.presentError(error)
            case .ok(let session):
                session.isMuted = !session.isMuted
            }
        }
    }
}

//MARK: UI Updates
extension MainWindowController {
    /// Refreshes the user interface updating the recording button state, now
    /// playing state and mute button state.
    private func refreshUI() {
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .ok(let session):
                self?.updateTrackStatusFields(track: session.currentTrack)
                self?.updateRecordButton(isRecording: session.isRecording)
                self?.updateMuteButton(isMuted: session.isMuted)
            case .fail(let error):
                self?.presentError(error)
            }
        }
    }

    private func updateTrackStatusFields(track: StaticSpotifyTrack?) {
        if let track = track {
            statusField.stringValue = track.name
            artistField.stringValue = track.artist
        } else {
            statusField.stringValue = NSLocalizedString("Ready to Record", comment: "")
            artistField.stringValue = ""
        }
    }

    private func updateRecordButton(isRecording: Bool) {
        if isRecording {
            recordButton.title = NSLocalizedString("Recording", comment: "")
            recordButton.state = .on
        } else {
            recordButton.title = NSLocalizedString("Record", comment: "")
            recordButton.state = .off
        }
    }

    private func updateMuteButton(isMuted: Bool) {
        if isMuted {
            muteButton.state = .on
            muteButton.image = #imageLiteral(resourceName: "Muted")
        } else {
            muteButton.state = .off
            muteButton.image = #imageLiteral(resourceName: "Unmuted")
        }
    }
}


//MARK: Helper Functions
extension MainWindowController {
    /// Presents a sheet built from the description and recovery suggestion
    /// of `error`.
    ///
    /// - parameter error: The error to present.
    /// - parameter block: A block to execute after the error is dismissed.
    private func presentError(_ error: Error, block: ((NSApplication.ModalResponse) -> Void)?) {
        guard let window = window else {
            return
        }

        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window, completionHandler: block)
    }
}

//MARK: Notification Handling
extension MainWindowController {
    private func muteStateDidChange(noti: MuteStateDidChange) {
        updateMuteButton(isMuted: noti.newMuteState)
    }

    private func recordingStateDidChange(noti: RecordingStateDidChange) {
        updateRecordButton(isRecording: noti.isRecording)
    }

    private func trackDidChange(noti: TrackDidChange) {
        updateTrackStatusFields(track: noti.newTrack)
    }

    private func didEncounterError(noti: DidEncounterError) {
        presentError(noti.error)
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
