//
//  GoRewindProcessCommunicator.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 09.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation
import os.log

public class GoRewindProcessCommunicator {
    
    public enum LaunchParam {
        case debug
        case customServiceNamePrefix(String)
        case plist(URL)
    }
    
    private static func infoPlist(plistUrl: URL) -> Dictionary<String, AnyObject>? {    
        guard FileManager.default.fileExists(atPath: plistUrl.path) else { return nil }
        
        os_log("Using plist: %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               plistUrl.path) 
        
        if let pListData = FileManager.default.contents(atPath: plistUrl.path) {
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
    
    public static func setupConnection(with param: LaunchParam, launchAgentFrom applicationSupportDirectory: URL? = nil) {
        switch param {
        case .debug:
            GoRewindProcessConstants.serviceNamePrefix = "dev."
            
        case let .customServiceNamePrefix(prefix):
            GoRewindProcessConstants.serviceNamePrefix = prefix + "."
            
        case let .plist(plistUrl):
            if let plist = infoPlist(plistUrl: plistUrl), let commit = plist["M37GitHash"] as? String {
                let idx = commit.index(commit.startIndex, offsetBy: 8)
                let sub = commit[..<idx]
                GoRewindProcessConstants.serviceNamePrefix = String(sub) + "."
            }
        }
        
        if let applicationSupportDirectory = applicationSupportDirectory {
            OEXPCCAgentConfiguration.defaultConfiguration(withName: GoRewindProcessConstants.serviceName(), applicationSupportDirectory: applicationSupportDirectory)
        }
        
        OEXPCCAgent.defaultAgent(withServiceName: GoRewindProcessConstants.fullServiceName())
        
        os_log("SetupConnection. fullServiceName: %{public}@. Start agent? %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               GoRewindProcessConstants.fullServiceName(), applicationSupportDirectory?.path ?? "[-]") 
    }
    
    // TODO: should terminate only on update? What about nativeMessagingHost?
    public static func terminate() {
        OEXPCCAgentConfiguration.current()?.tearDownAgent()
    }
}
