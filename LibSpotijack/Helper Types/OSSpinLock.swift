//
//  OSSpinLock.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 25/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import os.lock

final class OSUnfairLock: NSLocking {

    private var _lock = os_unfair_lock()

}
