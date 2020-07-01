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

    func applicationDidFinishLaunching(_ notification: Notification) {

        Preferences.shared.registerDefaultValues()

        SpotifyApplication.launch { [self] result in
            switch result {
            case .success(let app):
                sessionCoordinator = SessionCoordinator(musicApp: app, recorderFactory: { device in
                    AudioRecorder(inputDevice: device as! AVCaptureDevice) // swiftlint:disable:this force_cast
                })
                mainWindowController = MainWindowController(musicApp: app, sessionCoordinator: sessionCoordinator)
                _ = applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)

            case .failure(let error):
                NSApplication.shared.presentError(error)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindowController.showWindow(self)
            return false
        }

        return true
    }
//
//    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//        let isSpotijacking = (try? SpotijackSessionManager.shared().isSpotijacking) ?? false
//        return !isSpotijacking
//    }
//
//    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
//        let isSpotijacking = (try? SpotijackSessionManager.shared().isSpotijacking) ?? false
//        if isSpotijacking,
//           let window = mainWindowController.window {
//            presentTerminationWarning(window: window)
//            return .terminateLater
//        } else {
//            return .terminateNow
//        }
//    }
//
//    func applicationWillTerminate(_ notification: Notification) {
//        let isSpotijacking = (try? SpotijackSessionManager.shared().isSpotijacking) ?? false
//        if isSpotijacking {
//            do {
//                try? SpotijackSessionManager.shared().stopSpotijacking()
//            }
//        }
//    }
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
        alert.informativeText = NSLocalizedString("SESSION_QUIT_MESSAGE",
                                                  comment: "Asking if you want to quit")
        alert.messageText = NSLocalizedString("SESSION_QUIT_INFORMATIVE",
                                              comment: "Saying that a recording is in progress.")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                NSApp.reply(toApplicationShouldTerminate: false)
            } else {
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }
    }
}
