//
//  MainWindowController.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    //MARK: Interface Builder Outlets
    @IBOutlet weak var statusField: NSTextField!
    @IBOutlet weak var artistField: NSTextField!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var muteButton: NSButton!

    //MARK: Window Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()
    
        print("Hello world from MainWindowController")
    }

    //MARK: Interface Actions
    @IBAction func recordButtonClicked(_ sender: NSButton) {
    }

    @IBAction func muteButtonClicked(_ sender: NSButton) {
    }
}
