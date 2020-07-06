//
//  FakeCaptureDevice.swift
//  LibSpotijackTests
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import AVFoundation
@testable import LibSpotijack

struct FakeCaptureDevice: AVCaptureDeviceConvertible {
    var resolvedDevice: AVCaptureDevice { fatalError("Not implemented") }
}
