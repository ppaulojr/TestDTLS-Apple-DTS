//
//  NetInterfaceTypeQuery.swift
//  TestDTLS
//
//  Created by Pedro Paulo Oliveira Junior on 15/01/19.
//  Copyright © 2019 Trinity. All rights reserved.
//

import Foundation

struct NetInterfaceTypeQuery {
    
    func runningIPInterfaces() -> InterfaceQueryResult {
        var ethernetInterfaces = [IPInterface]()
        var cellInterfaces = [IPInterface]()
        var linkInterfaceNames = [String: InterfaceType]()
        var addrs: UnsafeMutablePointer<ifaddrs>?
        getifaddrs(&addrs)
        let addr = addrs
        
        while let ifaddr = addrs?.pointee {
            addrs = ifaddr.ifa_next
            let interfaceName = String(cString: ifaddr.ifa_name)
            let family = ifaddr.ifa_addr.pointee.sa_family
            
            if family == AF_LINK {
                let ifdata = ifaddr.ifa_data.assumingMemoryBound(to: if_data.self)
                guard let interface = InterfaceType(ifi_type: Int32(ifdata.pointee.ifi_type)) else { continue }
                let isRunning = ifaddr.ifa_flags & UInt32(IFF_RUNNING)
                if isRunning > 0 {
                    linkInterfaceNames[interfaceName] = interface
                }
            }
            else if family == AF_INET, let interface = linkInterfaceNames[interfaceName] {
                let ipInterface = ifaddr.ifa_addr.withSockAddrIn {
                    IPInterface(type: interface, name: interfaceName, address: $0.pointee)
                }
                interface ~= .ethernet ? ethernetInterfaces.append(ipInterface) : cellInterfaces.append(ipInterface)
            }
        }
        freeifaddrs(addr)
        return InterfaceQueryResult(ethernetInterfaces: ethernetInterfaces, cellInterfaces: cellInterfaces)
    }
}

extension NetInterfaceTypeQuery {
    
    struct IPInterface {
        
        let type: InterfaceType
        let name: String
        let address: sockaddr_in
    }
    
    struct InterfaceQueryResult {
        
        let ethernetInterfaces: [NetInterfaceTypeQuery.IPInterface]
        let cellInterfaces: [NetInterfaceTypeQuery.IPInterface]
        
        var interfacesByType: [InterfaceType: [NetInterfaceTypeQuery.IPInterface]] {
            return [.ethernet: ethernetInterfaces, .cell: cellInterfaces]
        }
        
        var allInterfaces: [NetInterfaceTypeQuery.IPInterface] {
            return ethernetInterfaces + cellInterfaces
        }
        
        var isEmpty: Bool {
            return ethernetInterfaces.isEmpty && cellInterfaces.isEmpty
        }
    }
}

enum InterfaceType: CustomStringConvertible {
    
    case ethernet
    case cell
    
    init?(ifi_type: Int32) {
        switch ifi_type {
        case IFT_ETHER: self = .ethernet
        case IFT_CELLULAR: self = .cell
        default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .cell: return "cell"
        case .ethernet: return "ethernet"
        }
    }
}

extension NetInterfaceTypeQuery.IPInterface: Equatable {
    
    static func ==(lhs: NetInterfaceTypeQuery.IPInterface, rhs: NetInterfaceTypeQuery.IPInterface) -> Bool {
        return lhs.type ~= rhs.type && lhs.name == rhs.name
    }
}


extension NetInterfaceTypeQuery.IPInterface: CustomStringConvertible {
    
    var description: String {
        return "\(name): \(type) \(String(cString: inet_ntoa(address.sin_addr)))"
    }
}
