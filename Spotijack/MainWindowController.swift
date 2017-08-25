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

internal class MainWindowController: NSWindowController {
    // MARK: Interface Builder Outlets
    @IBOutlet private weak var statusField: NSTextField!
    @IBOutlet private weak var artistAlbumField: NSTextField!
    @IBOutlet private weak var recordButton: NSButton!
    @IBOutlet private weak var muteButton: NSButton!

    // MARK: Notification Observer Tokens
    private var _muteStateDidChangeObserver: NotificationObserver?
    private var _didEncounterErrorObserver: NotificationObserver?
    private var _recordingStateDidChangeObserver: NotificationObserver?
    private var _trackDidChangeObserver: NotificationObserver?
    private var _didReachEndOfQueueObserver: NotificationObserver?

    // MARK: Window Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()

        registerForSpotijackNotifications()

        // Start polling and update the UI
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .ok(let session):
                session.startPolling(every: 0.1)
                self?.refreshUI()
            case .fail(let error):
               _ = self?.presentError(error)
            }
        }
    }
}

// MARK: - UI Actions
extension MainWindowController {
    @IBAction func recordButtonClicked(_ sender: NSButton) {
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .fail(let error):
               _ = self?.presentError(error)
            case .ok(let session):
                if session.isSpotijacking {
                    session.stopSpotijackSession()
                } else {
                    do {
                        try session.startSpotijackSession(config: Preferences.shared.recordingConfiguration)
                    } catch (let error) {
                       _ = self?.presentError(error)
                    }
                }
            }
        }
    }

    @IBAction func muteButtonClicked(_ sender: NSButton) {
        SpotijackSessionManager.shared.establishSession { [weak self] sessionResult in
            switch sessionResult {
            case .fail(let error):
               _ = self?.presentError(error)
            case .ok(let session):
                session.isMuted = !session.isMuted
            }
        }
    }
}

// MARK: UI Updates
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
               _ = self?.presentError(error)
            }
        }
    }

    private func updateTrackStatusFields(track: StaticSpotifyTrack?) {
        if let track = track {
            statusField.stringValue = track.name
            artistAlbumField.stringValue = "\(track.artist) — \(track.album)"
        } else {
            statusField.stringValue = NSLocalizedString("Ready to Record", comment: "")
            artistAlbumField.stringValue = ""
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

// MARK: - Notification Handling
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
        _ = self.presentError(noti.error)
    }

    private func didReachEndOfPlaybackQueue(noti: DidReachEndOfPlaybackQueue) {
        guard Preferences.shared.shouldNotifyWhenFinished else {
            return
        }

        let notification = NSUserNotification()
        notification.title = NSLocalizedString("SESSION_END_NOTI",
                                               comment: "Title of notification saying the session has ended.")
        notification.informativeText = NSLocalizedString("SESSION_END_NOTI_SUBT",
                                                         comment: "Explanation of why session has ended.")

        NSUserNotificationCenter.default.deliver(notification)
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

        _didReachEndOfQueueObserver = notificationCenter.addObserver(
            forType: DidReachEndOfPlaybackQueue.self,
            object: sessionManager,
            queue: .main,
            using: { [weak self] noti in self?.didReachEndOfPlaybackQueue(noti: noti) })
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
        } catch (let error) {
            return super.presentError(error)
        }
    }
}
