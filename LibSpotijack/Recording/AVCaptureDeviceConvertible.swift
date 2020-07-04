//
//  CaptureDevice.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import AVFoundation

/// A type that can be converted to an `AVCaptureDevice`.
///
/// This exists soley as a really convoluted way to stub out AVCaptureDevice when needed.
///
protocol AVCaptureDeviceConvertible {
    var resolvedDevice: AVCaptureDevice { get }
}

extension AVCaptureDevice: AVCaptureDeviceConvertible {
    var resolvedDevice: AVCaptureDevice { self }
}
