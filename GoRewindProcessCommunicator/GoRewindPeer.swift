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
    
    public var service: S?
    public var onHandshake: ((_ service: S) -> ())?
    public var onParentProcessTermination: (() -> Void)?
    
    public init(handler: GoRewindProcessProtocol, localProtocol: Protocol, remoteProtocol: Protocol, currentContextIdentifier: ContextIdentifier) {
        self.listener = NSXPCListener.anonymous()
        self.localProtocol = localProtocol
        self.remoteProtocol = remoteProtocol
        self.handler = handler
        self.currentContextIdentifier = currentContextIdentifier
        
        super.init()
        
        self.listener.delegate = self
        
        self.startMonitoringParent()
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
    
    private func startMonitoringParent() {
        let _argument = ProcessInfo.processInfo.arguments.filter { (arg) -> Bool in
            return arg.hasPrefix("--parent_pid=")
            }.first 
        
        guard let argument = _argument else {
            os_log("No parent_pid set.", type: .info)
            return
        }
        
        let idx = argument.range(of: "--parent_pid=")!.upperBound
        let sPid = argument.suffix(from: idx)
        
        guard let pid = Int32(sPid) else {
            os_log("Can't cast parent pid.", type: .info)
            return
        }
        
        os_log("Parent pid: %{public}d", type: .info, pid)
        
        let source = DispatchSource.makeProcessSource(identifier: pid, 
                                                      eventMask: DispatchSource.ProcessEvent.exit, 
                                                      queue: DispatchQueue.global())
        source.setEventHandler {
            os_log("Parent process %{public}d exited.", 
                   type: .info,
                   pid)            
            source.cancel()
            self.onParentProcessTermination?()
        }
        source.resume()
    }
}
