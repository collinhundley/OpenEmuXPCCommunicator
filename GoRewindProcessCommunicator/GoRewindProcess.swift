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
    
    private var processConnection: NSXPCConnection?
    private var process: Process?
    private let remoteContextIdentifier: ContextIdentifier
    private let localProtocol: Protocol
    private let remoteProtocol: Protocol
    private var handler: GoRewindProcessProtocol
    private var shouldTerminate: Bool = false
    private var launchUrl: URL
    
    public init?(launchUrl: URL, arguments: [String] = [], localProtocol: Protocol, remoteProtocol: Protocol, handler: GoRewindProcessProtocol, remoteContextIdentifier: ContextIdentifier = UUID().uuidString) {
        self.launchUrl = launchUrl
        self.remoteContextIdentifier = remoteContextIdentifier
        self.remoteProtocol = remoteProtocol
        self.localProtocol = localProtocol
        self.handler = handler

        let config = OEXPCCAgentConfiguration.current()
        
        guard let serviceName = config?.agentServiceNameProcessArgument() else {
            print("agentServiceNameProcessArgument not defined.")
            return nil    
        }
        
        guard let processIdentifier = config?.processIdentifierArgument(forIdentifier: remoteContextIdentifier) else {
            print("processIdentifier not defined.")
            return nil
        }
        
        os_log("Launch with arguments. ServiceName: %{public}@. ProcessIdentifier: %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               serviceName, remoteContextIdentifier, processIdentifier) 
        
        process = Process()
        process?.executableURL = launchUrl
        process?.arguments = [serviceName, processIdentifier] + arguments
        process?.terminationHandler = { [weak self] _process in
            guard let self = self else { return }
            if !self.shouldTerminate && _process.terminationReason == .uncaughtSignal {
                print("Subprocess \(_process.executableURL?.absoluteString ?? "[unknown]") quit unexpectedly [reason \(_process.terminationStatus)]. Trying to re-run...")
                
                // re-creating new `process` (An Process object can only be run once.)
                _process.terminate() // Just in case
                self.process = _process.lightCopy()
                self.run()
            }
        }
    }
    
    public func run() {     
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
            self.processConnection?.resume()
            
            self.service = self.processConnection?.remoteObjectProxyWithErrorHandler { error in
                print("Remote process error:", error)
                } as? S
            
            self.service?.handshake {
                self.onHandshake?()
            }
        })
    }
    
    public func terminate() {
        shouldTerminate = true
        process?.terminate()
        process = nil
    }
}
