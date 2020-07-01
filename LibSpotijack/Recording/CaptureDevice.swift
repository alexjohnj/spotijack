//
//  CaptureDevice.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 01/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

public protocol CaptureDevice { }

// MARK: - AVFoundation Integration

import AVFoundation

extension AVCaptureDevice: CaptureDevice { }
