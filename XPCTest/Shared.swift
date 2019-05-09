//
//  Shared.swift
//  XPCTest
//
//  Created by Konstantin Gonikman on 08.05.19.
//

import Foundation
import GoRewindProcessCommunicator

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
}
