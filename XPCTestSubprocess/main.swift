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

GoRewindProcessCommunicator.setupConnection(with: .customServiceNamePrefix("xpctest"))

peer = GoRewindPeer<RecorderToAppProtocol>(handler: mainAppHandler, 
                                           localProtocol: AppToRecorderProtocol.self, 
                                           remoteProtocol: RecorderToAppProtocol.self, 
                                           currentContextIdentifier: ContextIdentifiers.recorder,
                                           exitWhenParentExits: true)
peer.onHandshake = { s in
    print("Sub:Handshake")
    service = s
}
peer.listen()

CFRunLoopRun()
