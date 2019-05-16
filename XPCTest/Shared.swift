//
//  Shared.swift
//  XPCTest
//
//  Created by Konstantin Gonikman on 08.05.19.
//

import Foundation
import GoRewindProcessCommunicator
import os.log


@objc
public protocol AppToRecorderProtocol: GoRewindProcessProtocol {
    func toggleState()
    func retrieveState(_ isRecording: @escaping (Bool) -> Void)
}

@objc
public protocol RecorderToAppProtocol: GoRewindProcessProtocol {
    func updateStatistics(frameCount: Int, CPUperHour: Int)
}



public struct ContextIdentifiers {
    public static let recorder: ContextIdentifier = "XPCTestRecorder"
    public static let nativeMessagingHost: ContextIdentifier = "XPCTestNMH"
}

extension OSLog {
    static let recorder = OSLog(subsystem: "RewindKit", category: "Recorder")
    static let nativeMessagingHosts = OSLog(subsystem: "RewindKit", category: "NativeMessagingHosts")
}


//———————————————————————————————————————————————————————————————————————————————
// NativeMessagingHosts
//———————————————————————————————————————————————————————————————————————————————

@objc
public protocol AppToBrowserProtocol: GoRewindProcessProtocol {
    func handshakeEvent(data: [String: Any])
}

@objc
public protocol BrowserToAppProtocol: GoRewindProcessProtocol {
    func browserEvent(data: [String: Any])
}
