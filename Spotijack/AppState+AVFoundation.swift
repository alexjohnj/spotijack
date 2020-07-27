//
//  AppState+AVFoundation.swift
//  Spotijack
//
//  Created by Alex Jackson on 27/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import AVFoundation

extension AppState.InputDevice {
    init(avDevice: AVCaptureDevice) {
        self.init(id: avDevice.uniqueID, name: avDevice.localizedName)
    }
}
