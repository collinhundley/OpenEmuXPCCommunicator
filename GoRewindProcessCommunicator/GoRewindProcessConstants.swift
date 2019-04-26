//
//  GoConstants.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 12.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation

public typealias ContextIdentifier = String

public struct GoRewindProcessConstants {
    
    private static var serviceNamePrefix: String {
        #if DEBUG
        return "dev."
        #else
        return ""
        #endif
    }
    
    public static var fullServiceName: String {
        return "ai.m37.GoRewind.OEXPCCAgent." + serviceName
    }
    
    public static let serviceName = serviceNamePrefix + "gorewind-agent"
}
