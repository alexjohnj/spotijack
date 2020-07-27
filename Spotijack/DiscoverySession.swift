//
//  DiscoverySession.swift
//  Spotijack
//
//  Created by Alex Jackson on 27/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import Combine
import AVFoundation

protocol DeviceDiscoverySession {
    var devices: [AVCaptureDevice] { get }
}

final class InputDeviceDiscoverySession: DeviceDiscoverySession {

    private(set) var devices: [AVCaptureDevice]

    init() {
        let avDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        )

        devices = avDiscoverySession.devices
    }
}
