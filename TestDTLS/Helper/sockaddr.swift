//
//  sockaddr.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

import Foundation

extension sockaddr {
    
    func withSockAddrIn<Result>(_ map: (UnsafePointer<sockaddr_in>) -> Result) -> Result {
        var addr = self
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1, map)
        }
    }
}

extension sockaddr_storage {
    
    func withSockAddr<Result>(_ map: (UnsafePointer<sockaddr>) -> Result) -> Result {
        var addr = self
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, map)
        }
    }
    
    func withSockAddrMutable<Result>(_ map: (UnsafeMutablePointer<sockaddr>) -> Result) -> Result {
        var addr = self
        return withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, map)
        }
    }
    
}

extension sockaddr_in {
    
    func withSockAddr<Result>(_ map: (UnsafePointer<sockaddr>) -> Result) -> Result {
        var addr = self
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, map)
        }
    }
    
    func withSockAddrMutable<Result>(_ map: (UnsafeMutablePointer<sockaddr>) -> Result) -> Result {
        var addr = self
        return withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, map)
        }
    }
}

extension sockaddr_in {
    
    init?(ipAddress: String, port: Int?) {
        self.init(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size), sin_family: sa_family_t(AF_INET), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0)))
        guard let p = UInt16(exactly: port ?? 0) else { return nil }
        sin_port = in_port_t(p.bigEndian)
        let success = ipAddress.withCString { cstring in
            inet_pton(AF_INET, cstring, &sin_addr)
        }
        guard success == 1 else { return nil }
    }
    
    init?(wildCardAddressWithPort port: Int?) {
        self.init(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size), sin_family: sa_family_t(AF_INET), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0)))
        guard let p = UInt16(exactly: port ?? 0) else { return nil }
        sin_port = in_port_t(p.bigEndian)
        sin_addr.s_addr = INADDR_ANY.bigEndian
    }
    
    func addressAndPort() -> (String, String)? {
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var portBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
        return withSockAddr { sa in
            let result = getnameinfo(sa, socklen_t(sa.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &portBuffer, socklen_t(portBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV)
            return result == 0 ? (String(cString: hostBuffer), String(cString: portBuffer)) : nil
        }
    }
}

extension sockaddr_in: CustomStringConvertible {
    
    public var description: String {
        var addr = sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let result = inet_ntop(AF_INET, &addr, &buffer, socklen_t(buffer.count))
        let addrString = result.map { String(cString: $0) } ?? "unknown address"
        return addrString
    }
}

extension sockaddr_in: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return addressAndPort().map { $0.0 + ":" + $0.1 } ?? "nil"
    }
}

extension UnsafePointer where Pointee == sockaddr {
    
    func withSockAddrIn<Result>(_ map: (UnsafePointer<sockaddr_in>) -> Result) -> Result {
        return withMemoryRebound(to: sockaddr_in.self, capacity: 1, map)
    }
}

extension UnsafeMutablePointer where Pointee == sockaddr {
    
    func withSockAddrIn<Result>(_ map: (UnsafeMutablePointer<sockaddr_in>) -> Result) -> Result {
        return withMemoryRebound(to: sockaddr_in.self, capacity: 1, map)
    }
}

extension UnsafeMutablePointer where Pointee == sockaddr_in {
    
    func withSockAddr<Result>(_ map: (UnsafeMutablePointer<sockaddr>) -> Result) -> Result {
        return withMemoryRebound(to: sockaddr.self, capacity: 1, map)
    }
}
