//
//  MainWindowController.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import AppKit
import Combine
import LibSpotijack

internal class MainWindowController: NSWindowController {

    // MARK: Private Properties

    private let store: Store<AppState, AppMessage>
    private var cancellationBag: [AnyCancellable] = []

    // MARK: - Outlets

    @IBOutlet private weak var inputDevicePopUp: NSPopUpButton!
    @IBOutlet private weak var statusField: NSTextField!
    @IBOutlet private weak var artistAlbumField: NSTextField!
    @IBOutlet private weak var spotijackButton: NSButton!

    // MARK: - Initializers

    init(store: Store<AppState, AppMessage>) {
        self.store = store
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

        store.publisher
            .map { ($0.availableInputDevices, $0.selectedInputDevice) }
            .sink { [unowned self] devices, selectedDevice in
                let deviceNames = devices.map(\.name)

                self.inputDevicePopUp.removeAllItems()
                self.inputDevicePopUp.addItems(withTitles: deviceNames)

                if let selectedDevice = selectedDevice {
                    self.inputDevicePopUp.selectItem(withTitle: selectedDevice.name)
                } else {
                    self.inputDevicePopUp.selectItem(at: -1)
                }
            }
            .store(in: &cancellationBag)

        store.publisher.map(\.isRecording)
            .sink { [unowned self] isRecording in
                if isRecording {
                    self.spotijackButton.title = NSLocalizedString("Stop Recording", comment: "")
                } else {
                    self.spotijackButton.title = NSLocalizedString("Record", comment: "")
                }
            }
            .store(in: &cancellationBag)

        store.publisher.map(\.isRecording)
            .map { !$0 }
            .assign(to: \.isEnabled, on: inputDevicePopUp)
            .store(in: &cancellationBag)

        store.publisher.map(\.canStartRecording)
            .sink { [unowned self] canStartRecording in
                self.spotijackButton.isEnabled = canStartRecording
            }
            .store(in: &cancellationBag)

        store.publisher.map(\.currentTrack)
            .sink { [unowned self] track in
                if let track = track {
                    self.statusField.stringValue = track.name
                    self.artistAlbumField.stringValue = "\(track.artist) — \(track.album)"
                } else {
                    self.statusField.stringValue = NSLocalizedString("Ready to Record", comment: "")
                    self.artistAlbumField.stringValue = ""
                }
            }
            .store(in: &cancellationBag)
    }
}

// MARK: - UI Actions

extension MainWindowController {
    @IBAction func spotijackButtonClicked(_ sender: NSButton) {
        store.send(.toggleRecording)
    }

    @IBAction private func selectInputDevice(_ sender: NSPopUpButton) {
        let selectionIndex = sender.indexOfSelectedItem
        store.send(.selectInputDevice(index: selectionIndex))
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
