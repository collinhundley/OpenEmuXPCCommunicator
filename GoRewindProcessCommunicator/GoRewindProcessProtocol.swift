//
//  GoRewindProcessProtocol.swift
//  ProcessCommunicator
//
//  Created by Konstantin Gonikman on 10.04.19.
//  Copyright © 2019 Konstantin Gonikman. All rights reserved.
//

import Foundation

@objc
public protocol GoRewindProcessProtocol {
    // This isn't ideal. We'd rather implement it in a Protocol Extension, but unfortunately
    // it's not possible for @objc protocols. Use nasty inheritance instead?...
    func handshake(connectionIdentifier: String, completionHandler: @escaping () -> ())
}
