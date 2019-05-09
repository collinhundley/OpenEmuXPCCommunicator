//
//  ViewController.swift
//  XPCTest
//
//  Created by Konstantin Gonikman on 08.05.19.
//

import Cocoa
import GoRewindProcessCommunicator


final class RecorderHandler: RecorderToAppProtocol {
    func updateStatistics(frameCount: Int, CPUperHour: Int) {
        print("GOT frameCount: \(frameCount)")
    }
    
    func handshake(completionHandler: () -> ()) {
        completionHandler()
    }
}

final class ViewController: NSViewController {
    
    private var subProcess: GoRewindProcess<AppToRecorderProtocol>!    
//    private var recorderProcess: GoRewindRunningProcess<AppToRecorderProtocol>!
    private let recorderHandler = RecorderHandler()

    override func viewDidLoad() {
        super.viewDidLoad()

//        recorderProcess = GoRewindRunningProcess<AppToRecorderProtocol>(localProtocol: RecorderToAppProtocol.self, 
//                                                                        remoteProtocol: AppToRecorderProtocol.self, 
//                                                                        handler: recorderHandler, 
//                                                                        remoteContextIdentifier: "recorder")
//        
//        recorderProcess.onHandshake = {
//            print("fromRecorder:handshake")
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { 
//                print("send STOP")
//                self.recorderProcess.service?.toggleState()
//            }
//        }
//        
//        print("toRecorder:connect...")
//        recorderProcess.connect()
    }
    
    @IBAction func startSubprocess(_ sender: Any) {        
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("xpctest")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        GoRewindProcessCommunicator.setupConnection(with: .customServiceNamePrefix("xpctest"), launchAgentFrom: url)
        
        let subProcessFilePath = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("XPCTestSubprocess")        
        subProcess = GoRewindProcess<AppToRecorderProtocol>(launchUrl: subProcessFilePath, 
                                                                 arguments: [],
                                                                 localProtocol: RecorderToAppProtocol.self, 
                                                                 remoteProtocol: AppToRecorderProtocol.self, 
                                                                 handler: recorderHandler, 
                                                                 remoteContextIdentifier: ContextIdentifiers.recorder)        
        subProcess.onHandshake = {
            print("fromRecorder:handshake")
        }
        
        print("toRecorder:connect...")
        subProcess.run()
    }
}
