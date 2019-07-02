//
//  Process+Extensions.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 10.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation

extension Process {
    func lightCopy() -> Process {
        let newProcess = Process()
        newProcess.executableURL = self.executableURL
        newProcess.arguments = self.arguments
        newProcess.terminationHandler = self.terminationHandler
        newProcess.standardOutput = self.standardOutput
        newProcess.standardError = self.standardError
        return newProcess
    }
}
