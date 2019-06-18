//
//  GoRewindProcess.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 09.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation
import os.log

public class GoRewindProcess<S: GoRewindProcessProtocol> {    
    public var service: S?
    public var onHandshake: (() -> ())?
    public var onInterrupt: (() -> ())?
    public var onInvalidate: (() -> ())?
    public var onLaunchFailure: (() -> ())?
    public var shouldTerminate: Bool = false
    
    private var processConnection: NSXPCConnection?
    private var process: Process?
    private let remoteContextIdentifier: ContextIdentifier
    private let localProtocol: Protocol
    private let remoteProtocol: Protocol
    private var handler: GoRewindProcessProtocol
    private var connectionIdentifier: String
    private var launchUrl: URL
    private let maxAllowedRelaunches = 5
    private var currentLaunch = 0
    private var lastProcessLaunch: Date?
    
    public init?(launchUrl: URL, arguments: [String] = [], localProtocol: Protocol, remoteProtocol: Protocol, handler: GoRewindProcessProtocol, remoteContextIdentifier: ContextIdentifier = UUID().uuidString, connectionIdentifier: String = UUID().uuidString) {
        self.launchUrl = launchUrl
        self.remoteContextIdentifier = remoteContextIdentifier
        self.remoteProtocol = remoteProtocol
        self.localProtocol = localProtocol
        self.handler = handler
        self.connectionIdentifier = connectionIdentifier

        let config = OEXPCCAgentConfiguration.current()
        
        guard let serviceName = config?.agentServiceNameProcessArgument() else {
            print("agentServiceNameProcessArgument not defined.")
            return nil    
        }
        
        guard let processIdentifier = config?.processIdentifierArgument(forIdentifier: remoteContextIdentifier) else {
            print("processIdentifier not defined.")
            return nil
        }
        
        let pidArg = "--parent_pid=\(ProcessInfo.processInfo.processIdentifier)"
        
        os_log("Launch with arguments. ServiceName: %{public}@. ProcessIdentifier: %{public}@. pidArg: %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               serviceName, processIdentifier, pidArg) 
        
        process = Process()
        process?.executableURL = launchUrl
        process?.arguments = [serviceName, processIdentifier, pidArg] + arguments
        process?.terminationHandler = { [weak self] _process in
            guard let self = self else { return }
            if !self.shouldTerminate {
                print("Subprocess \(_process.executableURL?.absoluteString ?? "[unknown]") quit unexpectedly [reason \(_process.terminationStatus)]. Trying to re-run...")
                
                // re-creating new `process` (An Process object can only be run once.)
                _process.terminate() // Just in case
                self.process = _process.lightCopy()
                self.run()
            }
        }
    }
    
    public func run() {        
        guard currentLaunch < maxAllowedRelaunches else {
            os_log("Max number of relaunches (%{public}d) reached. Won't try anymore.", 
                   log: OSLog.xpc, 
                   type: .info, 
                   maxAllowedRelaunches) 
            onLaunchFailure?()
            return
        }
        
        // Don't count if the interval between launches is > 5 secs (might be a planned one?)
        if let lastProcessLaunch = lastProcessLaunch {
            let diff = Date().timeIntervalSince(lastProcessLaunch)
            if diff <= 5.0 {
                currentLaunch += 1
            } else {
                currentLaunch = 0
            }
        } else {
            currentLaunch += 1
        }
        lastProcessLaunch = Date()
        
        do {
            try self.process?.run()
        } catch {
            print("Can't run subprocess \(self.process?.executableURL?.absoluteString ?? "[unknown]"). Error: \(error)")
            return
        }
        
        os_log("Starting GoRewindProcess. fullServiceName: %{public}@. Via: %{public}@. launchUrl: %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               GoRewindProcessConstants.fullServiceName(), remoteContextIdentifier, launchUrl.path) 
        
        OEXPCCAgent.defaultAgent(withServiceName: GoRewindProcessConstants.fullServiceName())?.retrieveListenerEndpoint(forIdentifier: self.remoteContextIdentifier, completionHandler: { [weak self] endpoint in
            guard let self = self, 
                let theEndpoint = endpoint else {
                    print("Endpoint `\(endpoint.debugDescription)` is not available.")
                    return
            }
            
            self.processConnection = NSXPCConnection(listenerEndpoint: theEndpoint)
            self.processConnection?.remoteObjectInterface = NSXPCInterface(with: self.remoteProtocol)
            self.processConnection?.exportedObject = self.handler
            self.processConnection?.exportedInterface = NSXPCInterface(with: self.localProtocol)
            self.processConnection?.interruptionHandler = self.onInterrupt
            self.processConnection?.invalidationHandler = self.onInvalidate
            self.processConnection?.resume()
            
            self.service = self.processConnection?.remoteObjectProxyWithErrorHandler { error in
                print("Remote process error:", error)
                } as? S
            
            self.service?.handshake(connectionIdentifier: self.connectionIdentifier) {
                self.onHandshake?()
            }
        })
    }
    
    public func kill() {
        shouldTerminate = true
        process?.terminate()
        process = nil
    }
}
