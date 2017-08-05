//
//  AppDelegate.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa
import LibSpotijack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var mainWindowController: MainWindowController = MainWindowController(windowNibName: NSNib.Name("MainWindow"))

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Display the main window
        let _ = applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindowController.showWindow(self)
            return false
        }

        return true
    }

    @IBAction private func openPreferencesWindow(_ sender: NSMenuItem) {
        fatalError("Not Implemented")
    }
}
