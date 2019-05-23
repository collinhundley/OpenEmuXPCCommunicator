//
//  main.swift
//  XPCTestSubprocess
//
//  Created by Konstantin Gonikman on 08.05.19.
//

import Foundation
import GoRewindProcessCommunicator

final class MainAppHandler: AppToRecorderProtocol {
    func toggleState() {
        print("toggleState()")
    }
    
    func retrieveState(_ isRecording: @escaping (Bool) -> Void) {
        print("retrieveState()")
        isRecording(true)
    }    
    
    func handshake(completionHandler: () -> ()) {
        completionHandler()
    }
}

//———————————————————————————————————————————————————————————————————————————————

let mainAppHandler = MainAppHandler()
var peer: GoRewindPeer<RecorderToAppProtocol>!
var service: RecorderToAppProtocol?
let currentRunLoop = CFRunLoopGetCurrent()

GoRewindProcessCommunicator.setupConnection(with: .customServiceNamePrefix("xpctest")) { error in
    print("Can't connect to agent. Exiting...")
    CFRunLoopStop(currentRunLoop)
}

peer = GoRewindPeer<RecorderToAppProtocol>(handler: mainAppHandler, 
                                           localProtocol: AppToRecorderProtocol.self, 
                                           remoteProtocol: RecorderToAppProtocol.self, 
                                           currentContextIdentifier: ContextIdentifiers.recorder)
peer.onHandshake = { s in
    print("Sub:Handshake")
    service = s
}
peer.onParentProcessTermination = {
    print("Sub:Parent terminated.")
}
peer.listen()

DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { 
    exit(0)
}

CFRunLoopRun()
