//
//  MainWindowController.swift
//  Spotijack
//
//  Created by Alex Jackson on 24/07/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import AppKit
import Combine
import AVFoundation

import LibSpotijack

import os.log

private let log = OSLog(subsystem: "org.alexj.Spotijack.UIEvents", category: "MainWindowController")

internal class MainWindowController: NSWindowController {

    // MARK: Private Properties

    private let sessionCoordinator: SessionCoordinator
    private let musicApp: MusicApplication

    private var cancellationBag: [AnyCancellable] = []

    @Published private var availableInputDevice: [AVCaptureDevice] = []
    @Published private var selectedInputDevice: AVCaptureDevice? {
        didSet {
            if let device = selectedInputDevice {
                os_log(.default, log: log, "Selected input device: %s", device.localizedName)
            } else {
                os_log(.default, log: log, "Deselected any input device.")
            }
        }
    }

    // MARK: - Outlets

    @IBOutlet private weak var inputDevicePopUp: NSPopUpButton!
    @IBOutlet private weak var statusField: NSTextField!
    @IBOutlet private weak var artistAlbumField: NSTextField!
    @IBOutlet private weak var spotijackButton: NSButton!

    // MARK: - Initializers

    init(musicApp: MusicApplication, sessionCoordinator: SessionCoordinator) {
        self.musicApp = musicApp
        self.sessionCoordinator = sessionCoordinator
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

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown, .builtInMicrophone], mediaType: .audio, position: .unspecified)
        self.availableInputDevice = deviceDiscoverySession.devices
        self.selectedInputDevice = availableInputDevice.first

        NotificationCenter.default.publisher(for: .AVCaptureDeviceWasConnected)
            .sink { [unowned self] note in
                self.availableInputDevice.append(note.object as! AVCaptureDevice) // swiftlint:disable:this force_cast
            }
            .store(in: &cancellationBag)

        NotificationCenter.default.publisher(for: .AVCaptureDeviceWasDisconnected)
            .sink { [unowned self] note in
                let device = note.object as! AVCaptureDevice // swiftlint:disable:this force_cast
                self.availableInputDevice.removeAll(where: { $0 == device })
                if device == selectedInputDevice {
                    selectedInputDevice = nil
                }
            }
            .store(in: &cancellationBag)

        $availableInputDevice.sink { [unowned self] devices in
            let deviceNames = devices.map(\.localizedName)
            inputDevicePopUp.removeAllItems()
            inputDevicePopUp.addItems(withTitles: deviceNames)
            if let selection = selectedInputDevice {
                inputDevicePopUp.selectItem(withTitle: selection.localizedName)
            }
        }
        .store(in: &cancellationBag)

        $selectedInputDevice
            .map { $0 != nil }
            .assign(to: \.isEnabled, on: spotijackButton)
            .store(in: &cancellationBag)

        sessionCoordinator.$state
            .sink { [unowned self] state in
                switch state {
                case .recording:
                    spotijackButton.title = NSLocalizedString("Stop Recording", comment: "")
                    spotijackButton.state = .on

                case .notRecording:
                    spotijackButton.title = NSLocalizedString("Record", comment: "")
                    spotijackButton.state = .off

                case .endingRecording:
                    spotijackButton.title = "Ending Recording…"
                    spotijackButton.state = .off
                }
            }
            .store(in: &cancellationBag)

        sessionCoordinator.$state
            .map { state in
                switch state {
                case .recording,
                     .endingRecording:
                    return false
                case .notRecording:
                    return true
                }
            }
            .assign(to: \.isEnabled, on: self.inputDevicePopUp)
            .store(in: &cancellationBag)

        musicApp.trackIDPublisher
            .map { [musicApp] _ in musicApp.currentTrack }
            .sink { [unowned self] track in
                if let track = track {
                    statusField.stringValue = track.name
                    artistAlbumField.stringValue = "\(track.artist) — \(track.album)"
                } else {
                    statusField.stringValue = NSLocalizedString("Ready to Record", comment: "")
                    artistAlbumField.stringValue = ""
                }
            }
            .store(in: &cancellationBag)
    }
}

// MARK: - UI Actions
extension MainWindowController {
    @IBAction func spotijackButtonClicked(_ sender: NSButton) {
        switch sessionCoordinator.state {
        case .endingRecording:
            return

        case .recording:
            sessionCoordinator.stopRecording()

        case .notRecording:
            do {
                guard let inputDevice = selectedInputDevice else {
                    NSSound.beep()
                    return
                }

                try sessionCoordinator.startRecording(from: inputDevice)
            } catch {
                _ = presentError(error)
            }
        }
    }

    @IBAction private func selectInputDevice(_ sender: NSPopUpButton) {
        let selectionIndex = sender.indexOfSelectedItem
        guard selectionIndex < availableInputDevice.count else { return }
        selectedInputDevice = availableInputDevice[selectionIndex]
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
