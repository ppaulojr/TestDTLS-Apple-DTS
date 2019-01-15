//
//  UDPSocket.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

//
//  UDPSocket.swift
//
//  Created by Matthew Carroll on 11/6/17.
//  Copyright © 2017 Trinity Mobile Networks, Inc. All rights reserved.
//

import Foundation

public struct Endpoint {
    
    public let address: String
    public let port: String
    public let version: IPVersion
    
    public init(address: String, port: String, version: IPVersion) {
        self.address = address
        self.port = port
        self.version = version
    }
    
    var byteSize: Int {
        return address.count + port.count
    }
    
    public enum IPVersion {
        case four
        case six
    }
}

final class UDPSocket {
    
    var didRead: (Data) -> () = { _ in }
    private let readSource: DispatchSourceRead
    private let queue = DispatchQueue(label: "")
    private let remoteAddr: sockaddr_in
    private let socket: Int32
    
    convenience init?(endpoint: Endpoint, bindToInterface interface: String) {
        guard let sockAddr = sockaddr_in(ipAddress: endpoint.address, port: Int(endpoint.port)) else {
            return nil
        }
        self.init(remoteAddr: sockAddr, bindToInterface: interface)
    }
    
    init?(remoteAddr: sockaddr_in, bindToInterface interface: String) {
        let newSocket = Darwin.socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard newSocket != -1 else {
            return nil
        }
        var index = if_nametoindex(interface)
        guard index > 0 else {
            return nil
        }
        let result = setsockopt(newSocket, IPPROTO_IP, IP_BOUND_IF, &index, socklen_t(MemoryLayout.size(ofValue: index)))
        guard result == 0 else {
            return nil
        }
        socket = newSocket
        self.remoteAddr = remoteAddr
        readSource = DispatchSource.makeReadSource(fileDescriptor: newSocket, queue: queue)
        unowned let _self = self
        readSource.setEventHandler {
            _self.readData()
        }
        readSource.setCancelHandler {
            Darwin.close(newSocket)
        }
        readSource.activate()
    }
    
    func bindToInterface(named: String) {
        var index = if_nametoindex(named)
        guard index > 0 else {
            strError()
            return
        }
        let result = setsockopt(Int32(readSource.handle), IPPROTO_IP, IP_BOUND_IF, &index, socklen_t(MemoryLayout.size(ofValue: index)))
        guard result == 0 else {
            strError()
            return
        }
    }
    
    func sendData(_ data: Data) {
        queue.async { self._sendData(data) }
    }
    
    private func _sendData(_ data: Data) {
        let count = data.count
        let length = socklen_t(remoteAddr.sin_len)
        _ = remoteAddr.withSockAddr { sockAddr -> Int in
            data.withUnsafeBytes {
                sendto(socket, $0, count, 0, sockAddr, length)
            }
        }
    }
    
    private func readData() {
        let socketAddress = sockaddr_storage()
        var socketAddressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let size = 1500
        var response = [UInt8](repeating: 0, count: size)
        let bytesRead: Int = socketAddress.withSockAddrMutable {
            recvfrom(socket, &response, size, 0, $0, &socketAddressLength)
            //            look into DTLS fragment and check if it's fragmented
        }
        guard bytesRead > 0 else {
            return
        }
        let data = Data(response[..<bytesRead])
//        print(data.hexEncodedString(options: .upperCase))
        didRead(data)
    }
    
    func close() {
        readSource.cancel()
    }
    
    @discardableResult
    func strError(error: Bool = true) -> String? {
        guard error else { return nil }
        let message  = String(cString: strerror(errno))
        return message
    }
    
    deinit {
        close()
    }
}

