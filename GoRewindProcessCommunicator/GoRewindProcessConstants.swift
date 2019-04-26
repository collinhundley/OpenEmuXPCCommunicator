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
    
    // `M37GitBranch` key needs to be present in all targets
    private static var serviceNamePrefix: String {
        if let branch = (Bundle.main.object(forInfoDictionaryKey: "M37GitBranch") as? String) {
            return branch + "."
        } else {
            return ""
        }
    }
    
    public static var fullServiceName: String {
        return "ai.m37.GoRewind.OEXPCCAgent." + serviceName
    }
    
    public static let serviceName = serviceNamePrefix + "gorewind-agent"
}
