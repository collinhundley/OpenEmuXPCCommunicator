//
//  ViewController.swift
//  XPCTest
//
//  Created by Konstantin Gonikman on 08.05.19.
//

import Cocoa
import GoRewindProcessCommunicator
import os.log

fileprivate let log = OSLog(subsystem: "ai.m37.gorewindTest", category: "BrowserHandler")

final class RecorderHandler: RecorderToAppProtocol {
    func updateStatistics(frameCount: Int, CPUperHour: Int) {
        print("GOT frameCount: \(frameCount)")
    }
    
    func handshake(completionHandler: () -> ()) {
        completionHandler()
    }
}

final class BrowserHandler: BrowserToAppProtocol {
    
    func handshake(completionHandler: () -> ()) {
        os_log("handshake()", log: log, type: .info)
//        BrowserCommunicator.shared.pongBrowser()
        completionHandler()
    }
    
    func browserEvent(data: [String : Any]) {
        os_log("browserEvent() data %{public}@", log: log, type: .info, "\(data)")        
    }
}


final class ViewController: NSViewController {
    
    private var subProcess: GoRewindProcess<AppToRecorderProtocol>!    
//    private var recorderProcess: GoRewindRunningProcess<AppToRecorderProtocol>!
    private let recorderHandler = RecorderHandler()
    private var browserPeer: GoRewindPeer<AppToBrowserProtocol>!

    override func viewDidLoad() {
        super.viewDidLoad()

        GoRewindProcessCommunicator.setupConnection(with: .customServiceNamePrefix("xpctest"))
        
        let browserHandler = BrowserHandler()
        browserPeer = GoRewindPeer<AppToBrowserProtocol>(handler: browserHandler,
                                                         localProtocol: BrowserToAppProtocol.self,
                                                         remoteProtocol: AppToBrowserProtocol.self,
                                                         currentContextIdentifier: ContextIdentifiers.nativeMessagingHost)
        browserPeer.onHandshake = { service in
            print("handshake")

        }
        browserPeer.listen()
    }
    
    @IBAction func retrievePID(_ sender: Any) {
        GoRewindProcessCommunicator.clientPid(for: ContextIdentifiers.nativeMessagingHost, with: .customServiceNamePrefix("xpctest")) { (_pid) in

            if let _pid = _pid {
                let pid = Int32(_pid)
                print("PID to kill: \(pid)")
                kill(pid, SIGTERM)
            } else {
                print("No PID registered.")
            }
        }
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
