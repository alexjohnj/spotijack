//
//  AppState.swift
//  Spotijack
//
//  Created by Alex Jackson on 27/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack
import AVFoundation

// MARK: - Environment

struct AppEnvironment {
    var app: NSApplication
    var recordingSession: RecordingSession
    var deviceDiscoverySession: DeviceDiscoverySession
    var notificationCenter: NotificationCenter
}

// MARK: - Messages

enum AppMessage {
    case didFinishLaunching
    case terminate

    case inputDeviceAdded(AppState.InputDevice)
    case inputDeviceRemoved(AppState.InputDevice)
    case selectInputDevice(index: Int)

    case recordingSessionLoaded(Result<RecordingSession.Components, Error>)
    case trackDidChange(Track?)

    case failedToStartRecording(Error)
    case recordingStarted
    case recordingStopped
    case toggleRecording
}

// MARK: - Subscriptions

private func subscriptions(for musicApp: MusicApplication) -> Command<AppMessage> {
    return musicApp.trackIDPublisher
        .map { [musicApp] _ in musicApp.currentTrack }
        .map(AppMessage.trackDidChange)
        .eraseToCommand()
}

private func subscriptions(for session: SessionCoordinator) -> Command<AppMessage> {
    let isSessionRecording = session.$state
        .map { state -> Bool in
            switch state {
            case .startingRecording,
                 .recording,
                 .endingRecording:
                return true

            case .notRecording:
                return false
            }
        }

    return isSessionRecording
        .removeDuplicates()
        .map { $0 ? AppMessage.recordingStarted : AppMessage.recordingStopped }
        .eraseToCommand()
}

private func deviceAvailabilitySubscriptions(notificationCenter: NotificationCenter) -> Command<AppMessage> {
    return .merge(
        notificationCenter.publisher(for: .AVCaptureDeviceWasConnected)
            .compactMap { $0.object as? AVCaptureDevice }
            .map(AppState.InputDevice.init(avDevice:))
            .map(AppMessage.inputDeviceAdded)
            .eraseToCommand(),

        notificationCenter.publisher(for: .AVCaptureDeviceWasDisconnected)
            .compactMap { $0.object as? AVCaptureDevice }
            .map(AppState.InputDevice.init(avDevice:))
            .map(AppMessage.inputDeviceRemoved)
            .eraseToCommand()
    )
}

// MARK: - State

struct AppState: Equatable {

    struct InputDevice: Equatable {
        let id: String
        let name: String
    }

    var isRecording = false
    var isSessionLoaded = false
    var currentTrack: Track?

    var availableInputDevices: [InputDevice] = []
    var selectedInputDevice: InputDevice?

    /// Flag indicating if the application is waiting for recording to finish to terminate.
    var shouldTerminateWhenRecordingFinishes = false

    var canStartRecording: Bool {
        isSessionLoaded == true && selectedInputDevice != nil
    }
}

// MARK: - Reducer

let appReducer: Reducer<AppState, AppMessage, AppEnvironment> = Reducer { state, command, env in
    switch command {
    case .didFinishLaunching:
        state.availableInputDevices = env.deviceDiscoverySession.devices.map(AppState.InputDevice.init(avDevice:))
        state.selectedInputDevice = state.availableInputDevices.first

        return Command.merge(
            env.recordingSession.launch(SpotifyApplication.self)
                .map(AppMessage.recordingSessionLoaded)
                .eraseToCommand(),
            deviceAvailabilitySubscriptions(notificationCenter: env.notificationCenter)
        )

    case .recordingSessionLoaded(.success(let sessionComponents)):
        state.isSessionLoaded = true

        return Command.merge(
            subscriptions(for: sessionComponents.musicApplication),
            subscriptions(for: sessionComponents.sessionCoordinator)
        )

    case .recordingSessionLoaded(.failure(let error)):
        state.isSessionLoaded = false

        return Command.fireAndForget {
            env.app.presentError(error)
        }

    case .trackDidChange(let newTrack):
        state.currentTrack = newTrack
        return .none

    case .inputDeviceAdded(let device):
        state.availableInputDevices.append(device)

        if state.selectedInputDevice == nil {
            state.selectedInputDevice = device
        }

        return .none

    case .inputDeviceRemoved(let device):
        state.availableInputDevices.removeAll(where: { $0.id == device.id })

        if device.id == state.selectedInputDevice?.id {
            state.selectedInputDevice = state.availableInputDevices.first
        }

        return .none

    case .selectInputDevice(let index):
        guard index < state.availableInputDevices.count else {
            return .none
        }
        state.selectedInputDevice = state.availableInputDevices[index]

        return .none

    case .toggleRecording:
        guard let selectedInputDevice = state.selectedInputDevice,
              let captureDevice = env.deviceDiscoverySession.devices.first(where: { $0.uniqueID == selectedInputDevice.id }) else {
            return .none
        }

        return env.recordingSession.toggleRecording(using: captureDevice)
            .compactMap { result in
                if case .failure(let error) = result {
                    return AppMessage.failedToStartRecording(error)
                } else {
                    return nil
                }
            }
            .eraseToCommand()

    case .failedToStartRecording(let error):
        return Command.fireAndForget {
            env.app.presentError(error)
        }

    case .recordingStarted:
        state.isRecording = true
        return .none

    case .recordingStopped:
        state.isRecording = false

        if state.shouldTerminateWhenRecordingFinishes {
            return Command.fireAndForget {
                env.app.reply(toApplicationShouldTerminate: true)
            }
        } else {
            return .none
        }

    case .terminate:
        state.shouldTerminateWhenRecordingFinishes = true
        return env.recordingSession.stopRecording().fireAndForget()
    }
}
