//
//  Preferences.swift
//  Spotijack
//
//  Created by Alex Jackson on 05/08/2017.
//  Copyright © 2017 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack

class Preferences {
    static let shared = Preferences()
    private var defaults: UserDefaults
    
    private struct Keys {
        static let shouldDisableShuffling = "disableShuffle"
        static let shouldDisableRepeat = "disableRepeat"
        static let shouldMuteSpotify = "muteSpotifyWhenRecording"
        static let shouldNotifyWhenFinished = "notifyWhenRecordingFinishes"
    }
    
    var shouldDisableShuffling: Bool {
        get {
            return defaults.bool(forKey: Keys.shouldDisableShuffling)
        }
        
        set {
            defaults.set(newValue, forKey: Keys.shouldDisableShuffling)
        }
    }
    
    var shouldDisableRepeat: Bool {
        get {
            return defaults.bool(forKey: Keys.shouldDisableRepeat)
        }
        
        set {
            defaults.set(newValue, forKey: Keys.shouldDisableRepeat)
        }
    }
    
    var shouldMuteSpotify: Bool {
        get {
            return defaults.bool(forKey: Keys.shouldMuteSpotify)
        }
        
        set {
            defaults.set(newValue, forKey: Keys.shouldMuteSpotify)
        }
    }
    
    var shouldNotifyWhenFinished: Bool {
        get {
            return defaults.bool(forKey: Keys.shouldNotifyWhenFinished)
        }
        
        set {
            defaults.set(newValue, forKey: Keys.shouldNotifyWhenFinished)
        }
    }
    
    func registerDefaultValues() {
        let defaultValues: [String: Any] = [
            Keys.shouldDisableShuffling: true,
            Keys.shouldDisableRepeat: true,
            Keys.shouldMuteSpotify: false,
            Keys.shouldNotifyWhenFinished: true
        ]
        
        self.defaults.register(defaults: defaultValues)
    }
    
    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults

        self.registerDefaultValues()
    }
}

//MARK: LibSpotijack Integration
extension Preferences {
    /// Generates a `RecordingConfiguration` based on the user's preferences
    internal var recordingConfiguration: SpotijackSession.RecordingConfiguration {
        let config = SpotijackSession.RecordingConfiguration(
            muteSpotify: shouldMuteSpotify,
            disableShuffling: shouldDisableShuffling,
            disableRepeat: shouldDisableRepeat,
            pollingInterval: 0.1
        ) //MARK: TODO: Add preference for polling interval

        return config
    }
}

