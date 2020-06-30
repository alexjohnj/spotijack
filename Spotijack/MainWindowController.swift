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
import AVFoundation

internal class MainWindowController: NSWindowController {
    // MARK: Interface Builder Outlets
    @IBOutlet private weak var statusField: NSTextField!
    @IBOutlet private weak var artistAlbumField: NSTextField!
    @IBOutlet private weak var spotijackButton: NSButton!
    @IBOutlet private weak var muteButton: NSButton!

    private let _observationBag = NotificationObservationBag()

    // MARK: Window Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()

        registerForSpotijackNotifications()

        // Start polling and update the UI
        do {
            try SpotijackSessionManager.shared().startPolling(every: 0.1)
            let testDevice = AVCaptureDevice(uniqueID: "com.rogueamoeba.Loopback:02937F9F-20CD-4906-A22E-0024A99C6B65")!

            try SpotijackSessionManager.shared().setInputDevice(testDevice)
            refreshUI()
        } catch {
            _ = presentError(error)
        }

    }
}

// MARK: - UI Actions
extension MainWindowController {
    @IBAction func spotijackButtonClicked(_ sender: NSButton) {
        do {
            let session = try SpotijackSessionManager.shared()
            if session.isSpotijacking {
                session.stopSpotijacking()
            } else {
                try session.startSpotijacking(config: Preferences.shared.recordingConfiguration)
            }

            updateSpotijackButton(isSpotijacking: session.isSpotijacking)
        } catch {
            _ = presentError(error)
        }
    }

    @IBAction func muteButtonClicked(_ sender: NSButton) {
    }
}

// MARK: UI Updates
extension MainWindowController {
    /// Refreshes the user interface updating the recording button state, now
    /// playing state and mute button state.
    private func refreshUI() {
        do {
            let session = try SpotijackSessionManager.shared()
            updateTrackStatusFields(track: session.currentTrack)
            updateSpotijackButton(isSpotijacking: session.isSpotijacking)
        } catch {
            _ = presentError(error)
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

    private func updateSpotijackButton(isSpotijacking: Bool) {
        if isSpotijacking {
            spotijackButton.title = NSLocalizedString("Recording", comment: "")
            spotijackButton.state = .on
        } else {
            spotijackButton.title = NSLocalizedString("Record", comment: "")
            spotijackButton.state = .off
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

    private func didEndSpotijacking(noti: DidEndSpotijacking) {
        updateSpotijackButton(isSpotijacking: false)
    }

    /// Registers the window controller for notifications posted by
    /// SpotijackSessionManager
    private func registerForSpotijackNotifications() {
        do {
            let session = try SpotijackSessionManager.shared()
            let notificationCenter = session.notificationCenter

            notificationCenter.addObserver(
                forType: MuteStateDidChange.self,
                object: session,
                queue: .main,
                using: { [weak self] noti in self?.muteStateDidChange(noti: noti) }
            ).stored(in: _observationBag)

            notificationCenter.addObserver(
                forType: DidEncounterError.self,
                object: session,
                queue: .main,
                using: { [weak self] noti in self?.didEncounterError(noti: noti) }
            ).stored(in: _observationBag)

            notificationCenter.addObserver(
                forType: TrackDidChange.self,
                object: session,
                queue: .main,
                using: { [weak self] noti in self?.trackDidChange(noti: noti) }
            ).stored(in: _observationBag)

            notificationCenter.addObserver(
                forType: DidReachEndOfPlaybackQueue.self,
                object: session,
                queue: .main,
                using: { [weak self] noti in self?.didReachEndOfPlaybackQueue(noti: noti) }
            ).stored(in: _observationBag)

            notificationCenter.addObserver(
                forType: DidEndSpotijacking.self,
                object: session,
                queue: .main,
                using: { [weak self] noti in self?.didEndSpotijacking(noti: noti) }
            ).stored(in: _observationBag)
        } catch {
            print("Could not register MainWindowController for SpotijackSession notifications"
                + " because \(error.localizedDescription)")
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
