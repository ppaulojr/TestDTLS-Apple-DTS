//
//  DTLSiOS.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//
import Foundation
final class DTLS {
    
    private var context = SSLCreateContext(nil, .clientSide, .datagramType)!
    private var availableData = Data()
    private var readLeft = 0
    private(set) var isHandshakeFinished = Atomic(false)
    private let queue = DispatchQueue(label: "")
    var client: DTLSClient!
    private var datap: UnsafePointer<UInt8>!
    private var dataCount = 0
    
    private func configureContext() {
        func readSSL(connection: SSLConnectionRef, data: UnsafeMutableRawPointer, dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
            let _self = Unmanaged<DTLS>.fromOpaque(connection).takeUnretainedValue()
            print ("readSSL req with \(dataLength.pointee) and we have \(_self.availableData.count) on buffer")
            guard _self.availableData.count > 0 || _self.isHandshakeFinished.value else {
                dataLength.pointee = 0
                return errSSLWouldBlock
            }
            print ("readleft \(_self.readLeft)")

            if _self.readLeft == 0 {
                _self.readLeft = _self.isHandshakeFinished.value ? _self.dataCount : _self.availableData.count
            }
            print ("readleft: \(_self.readLeft) and dataLength: \(dataLength.pointee)")

            if _self.readLeft < dataLength.pointee {
                dataLength.pointee = _self.readLeft
            }
            let expected = dataLength.pointee
            _self.readLeft -= expected
            
            if _self.isHandshakeFinished.value {
                if _self.datap != nil {
                    data.copyMemory(from: _self.datap, byteCount: dataLength.pointee)
                    _self.datap = _self.datap.advanced(by: dataLength.pointee)
                }
            }
            else {
                print(_self.availableData.hexEncodedString(options: .upperCase))
                _self.availableData.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
                    data.copyMemory(from: p, byteCount: dataLength.pointee)
                }
                if _self.availableData.count >= expected {
                    _self.availableData.removeFirst(expected)
                }
                else {
                    print("I don't like here")
                    _self.availableData.removeAll()
                }
            }
            
            return errSecSuccess
        }
        
        func writeSSL(connection: SSLConnectionRef, data: UnsafeRawPointer, dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
            let d = Data(bytes: data, count: dataLength.pointee)
            let client = Unmanaged<DTLS>.fromOpaque(connection).takeUnretainedValue()
            client.client.sendData(d)
            return errSecSuccess
        }
        
        SSLClose(context)
        context = SSLCreateContext(nil, .clientSide, .datagramType)!
        SSLSetIOFuncs(context, readSSL, writeSSL)
        SSLSetSessionOption(context, .breakOnServerAuth, true)
        let connectionRef = Unmanaged<DTLS>.passUnretained(self).toOpaque()
        SSLSetConnection(context, connectionRef)
        isHandshakeFinished.value = false
        queue.async { self.availableData.removeAll() }
    }
    
    func read(data datap: UnsafePointer<UInt8>, count: Int) -> Data {
        var data = Data(count: count)
        var read = 0
        _ = queue.sync {
            self.datap = datap
            self.dataCount = count
            _ = data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt8>) in
                _ = SSLRead(self.context, UnsafeMutableRawPointer(p), count, &read)
//                if err != noErr {
//                    DDLogError("\(#function) failed SSLRead with OSSError \(err). Look it up on www.osstatus.com")
//                }
            }
        }
        return data[data.startIndex..<read]
    }
    
    func write(_ data: Data) {
        let count = data.count
        var written = 0
        queue.async {
            _ = data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
                SSLWrite(self.context, UnsafeRawPointer(p), count, &written)
            }
        }
    }
    
    // Return 0 in case of success or -1 if exceeded the number of retries
    func startHandshake() -> Int8 {
        configureContext()
        var result = errSecSuccess
        let MAX_FAILURE = 100
        var failureCount = 0
        repeat {
            result = SSLHandshake(context)
            if (result == errSSLWouldBlock) {
                Thread.sleep(forTimeInterval: 0.05)
                failureCount += 1
                if failureCount > MAX_FAILURE {
                    return -1
                }
            }
        } while (result == errSSLWouldBlock || result == errSSLPeerAuthCompleted)
        isHandshakeFinished.value = true
        return 0
    }
    
    func addData(_ data: Data) {
        queue.async {
            self.availableData.append(data)
        }
    }
}


@objc protocol DTLSClient {
    
    func sendData(_ data: Data)
}
