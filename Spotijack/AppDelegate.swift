//
//  AppDelegate.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import LibSpotijack

import AVFoundation

@NSApplicationMain
internal class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Private Properties

    private var sessionCoordinator: SessionCoordinator!
    private var mainWindowController: MainWindowController!
    private lazy var prefencesWindowController = PreferencesWindowController()
    private var appStore: Store<AppState, AppMessage>!

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.shared.registerDefaultValues()

        appStore = Store(
            initialState: AppState(),
            reducer: appReducer.debugMessages(),
            environment: AppEnvironment(
                app: NSApp,
                recordingSession: RecordingSession(),
                deviceDiscoverySession: InputDeviceDiscoverySession(),
                notificationCenter: .default
            )
        )

        appStore.send(.didFinishLaunching)

        mainWindowController = MainWindowController(store: appStore)
        _ = applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindowController.showWindow(self)
            return false
        }

        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if appStore.state.isRecording,
           let window = mainWindowController.window {
            presentTerminationWarning(window: window)
            return .terminateLater
        } else {
            return .terminateNow
        }
    }
}

// MARK: - UI Actions
extension AppDelegate {
    @IBAction private func openPreferencesWindow(_ sender: NSMenuItem) {
        prefencesWindowController.showWindow(self)
    }
}

// MARK: - Helper Functions

extension AppDelegate {

    /// Presents an alert sheet asking the user to verify they want to quit.
    /// The alert response invokes `NSApp.reply(toApplicationShouldTerminate:)`
    ///
    /// - parameter window: The window to attach the alert to.
    private func presentTerminationWarning(window: NSWindow) {
        let alert = NSAlert()
        alert.informativeText = NSLocalizedString("SESSION_QUIT_INFORMATIVE",
                                                  comment: "Asking if you want to quit")
        alert.messageText = NSLocalizedString("SESSION_QUIT_MESSAGE",
                                              comment: "Saying that a recording is in progress.")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                NSApp.reply(toApplicationShouldTerminate: false)
            } else {
                self.appStore.send(.terminate)
            }
        }
    }
}
