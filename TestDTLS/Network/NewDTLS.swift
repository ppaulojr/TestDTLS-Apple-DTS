//
//  NewDTLS.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 17/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

import Foundation
import Network

class DTLSiOSNew {
    var endpoint : NWEndpoint?
    var connection: NWConnection?
    let myQueue = DispatchQueue(label: "cellQueue")

    
    init(gateway: Endpoint) {
        let param = NWParameters.dtls
        param.prohibitedInterfaceTypes = [.wifi]
        connection = NWConnection(host: NWEndpoint.Host(gateway.address), port: 80, using: param)
        connection?.stateUpdateHandler = { (newState) in
            switch(newState) {
            case .ready:
            print("Connected")
            case .waiting(let error):
                self.connection?.restart()
                print("Waiting: \(error)")
            case .failed(let error):
                print("Failed: \(error)")
            default:
                break
            }
        }
        connection?.start(queue: myQueue)
    }
}
