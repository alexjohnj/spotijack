//
//  Constants.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 06/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation

internal enum Constants {
    internal typealias BundleInfo = (name: String, identifier: String)

    internal static let spotifyBundle: BundleInfo = ("Spotify", "com.spotify.client")
    internal static let audioHijackBundle: BundleInfo = ("Audio Hijack Pro", "com.rogueamoeba.AudioHijackPro2")

    internal static let libSpotijackBundle = Bundle(identifier: "org.alexj.LibSpotijack")!
}

