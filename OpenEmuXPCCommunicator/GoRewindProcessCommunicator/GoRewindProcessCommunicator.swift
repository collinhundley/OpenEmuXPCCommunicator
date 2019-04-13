//
//  GoRewindProcessCommunicator.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 09.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation

public class GoRewindProcessCommunicator {
    public static func terminate() {
        OEXPCCAgentConfiguration.current()?.tearDownAgent()
    }
}
