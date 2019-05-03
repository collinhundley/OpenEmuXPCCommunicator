//
//  OSLog+Extensions.swift
//  GoRewindProcessCommunicator
//
//  Created by Konstantin Gonikman on 03.05.19.
//

import Foundation
import os.log

extension OSLog {
    static let xpc = OSLog(subsystem: "", category: "GoRewindXPC")
}
