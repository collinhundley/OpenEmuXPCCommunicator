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
    
    private static func infoPlist() -> Dictionary<String, AnyObject>? {    
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).appendingPathComponent("../../../../Info.plist")
        
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        if let pListData = FileManager.default.contents(atPath: url.path) {
            do {
                let pListObject = try PropertyListSerialization.propertyList(from: pListData, options:PropertyListSerialization.ReadOptions(), format:nil)
                
                guard let pListDict = pListObject as? Dictionary<String, AnyObject> else {
                    return nil
                }
                
                return pListDict
                
            } catch {
                print("Error reading regions plist file: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    private static var serviceNamePrefix: String {        
        if let plist = infoPlist(), let branch = plist["M37GitBranch"] as? String {
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
