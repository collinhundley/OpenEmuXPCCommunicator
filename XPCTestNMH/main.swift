//
//  main.swift
//  XPCTestNMH
//
//  Created by Konstantin Gonikman on 16.05.19.
//

import Foundation
import os.log
import GoRewindProcessCommunicator


final class AppListener: AppToBrowserProtocol {
    func handshakeEvent(data: [String: Any]) {
        print("handshakeEvent")
    }
    
    func handshake(completionHandler: () -> ()) {
        completionHandler()
    }
}

let currentRunLoop = CFRunLoopGetCurrent()

let mainProcess: GoRewindRunningProcess<BrowserToAppProtocol>?

GoRewindProcessCommunicator.setupConnection(with: .customServiceNamePrefix("xpctest"))
let appListener = AppListener()

mainProcess = GoRewindRunningProcess<BrowserToAppProtocol>(localProtocol: AppToBrowserProtocol.self,
                                                           remoteProtocol: BrowserToAppProtocol.self,
                                                           handler: appListener,
                                                           remoteContextIdentifier: ContextIdentifiers.nativeMessagingHost)
mainProcess?.onHandshake = {
    os_log("Handshake", log: OSLog.nativeMessagingHosts, type: .info) 
}

mainProcess?.onInvalidate = {
    print("Connection invalidated.")
    CFRunLoopStop(currentRunLoop)
}

mainProcess?.onInterrupt = {
    print("Connection interrupted.")
    CFRunLoopStop(currentRunLoop)
}

os_log("Connect...", log: OSLog.nativeMessagingHosts, type: .info) 
mainProcess?.connect()

GoRewindProcessCommunicator.listenerPid(for: ContextIdentifiers.nativeMessagingHost, with: .customServiceNamePrefix("xpctest")) { (pid) in
    print("pid: \(pid ?? -1)")
}

CFRunLoopRun()
