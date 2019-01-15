//
//  CellUDPSession.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//
import Foundation

final class CellularUDPSession {
    
    private var socket: UDPSocket?
    private var gateways: Endpoint?
    private(set) var ipAddress: String?
    
    private let dtls = DTLS()
    
    var isConnected: Bool {
        return socket != nil
    }
    
    init(gateway: Endpoint) {
        dtls.client = self
        gateways = gateway
    }
    
    public func doSSLHandshake(_ useCell: Bool) -> Int8 {
        let iface = useCell ? NetInterfaceTypeQuery().runningIPInterfaces().cellInterfaces.first :
            NetInterfaceTypeQuery().runningIPInterfaces().ethernetInterfaces.first
        guard let endpoint = sockaddr_in(ipAddress: (gateways?.address)!, port: Int((gateways?.port)!)) else {return -2}
        guard let sock = udpSocket(on: iface!, to: endpoint) else { return -2}
        socket = sock
        if socket == nil {
            return -2
        }
        else
        {
            return self.dtls.startHandshake()
        }
    }
    
    private func udpSocket(on interface: NetInterfaceTypeQuery.IPInterface, to remoteAddr: sockaddr_in) -> UDPSocket? {
        guard let socket = UDPSocket(remoteAddr: remoteAddr, bindToInterface: interface.name) else { return nil }
        socket.didRead = readHandler
        ipAddress = interface.address.description
        return socket
    }
    
    private func readHandler(_ data: Data) {
            dtls.addData(data)
    }
    
    func sendData(_ data: Data) {
        socket?.sendData(data)
    }
    
    func cancelSession() {
        socket?.close()
        socket = nil
    }
    
    deinit {
        cancelSession()
    }
}

extension CellularUDPSession: DTLSClient {}
