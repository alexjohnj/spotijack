//
//  AppDelegate.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Hello, world")
    }

    @IBAction private func openPreferencesWindow(_ sender: NSMenuItem) {
        fatalError("Not Implemented")
    }
}
