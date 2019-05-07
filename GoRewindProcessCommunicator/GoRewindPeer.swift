//
//  GoRewindPeer.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 10.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation
import os.log

public class GoRewindPeer<S: GoRewindProcessProtocol>: NSObject, NSXPCListenerDelegate {
    private let listener: NSXPCListener
    private let localProtocol: Protocol
    private let remoteProtocol: Protocol
    private let handler: GoRewindProcessProtocol
    private let currentContextIdentifier: ContextIdentifier
    private let exitWhenParentExits: Bool
    
    public var service: S?
    public var onHandshake: ((_ service: S) -> ())?
    
    public init(handler: GoRewindProcessProtocol, localProtocol: Protocol, remoteProtocol: Protocol, currentContextIdentifier: ContextIdentifier, exitWhenParentExits: Bool = true) {
        self.exitWhenParentExits = exitWhenParentExits
        self.listener = NSXPCListener.anonymous()
        self.localProtocol = localProtocol
        self.remoteProtocol = remoteProtocol
        self.handler = handler
        self.currentContextIdentifier = currentContextIdentifier
        
        super.init()
        
        self.listener.delegate = self
    }
    
    public func listen() {
        listener.resume()
        os_log("Starting GoRewindPeer.listen(). fullServiceName: %{public}@. Via: %{public}@", 
               log: OSLog.xpc, 
               type: .info, 
               GoRewindProcessConstants.fullServiceName(), currentContextIdentifier) 
        
        OEXPCCAgent.defaultAgent(withServiceName: GoRewindProcessConstants.fullServiceName())?.register(listener.endpoint, forIdentifier: self.currentContextIdentifier, completionHandler: { success in
            print("Register OEXPCCAgent handler: \(success). [\(self.currentContextIdentifier)]")
        })
    }
    
    public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        if self.exitWhenParentExits {
            self.startMonitoringParent(with: newConnection.processIdentifier)
        }
        
        newConnection.exportedInterface = NSXPCInterface(with: self.localProtocol)
        newConnection.exportedObject = self.handler
        newConnection.remoteObjectInterface = NSXPCInterface(with: self.remoteProtocol)
        newConnection.resume()
        
        self.service = newConnection.remoteObjectProxyWithErrorHandler { error in
            print("Peer process error:", error)
        } as? S
        
        if let service = service {
            onHandshake?(service)
        }
        
        return true
    }
    
    private func startMonitoringParent(with pid_t: pid_t) {
        let source = DispatchSource.makeProcessSource(identifier: pid_t, 
                                                      eventMask: DispatchSource.ProcessEvent.exit, 
                                                      queue: DispatchQueue.global())
        source.setEventHandler {
            os_log("Parent process %{public}d exited", 
                   type: .info, 
                   pid_t)            
            source.cancel() // Not really needed...
            exit(1)
        }
        source.resume()
    }
}
