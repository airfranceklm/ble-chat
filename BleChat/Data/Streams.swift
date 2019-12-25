//
//  Streams.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation


extension UnsignedInteger {
    func write(to stream: OutputStream) {
        var value = self
        let byteArray = withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Self>.size) {
                $0
            }
        }
        stream.write(byteArray, maxLength: MemoryLayout<Self>.size)
    }
    
    static func read(from stream: InputStream) -> Self? {
        let ump = UnsafeMutablePointer<UInt8>.allocate(capacity: MemoryLayout<Self>.size)
        let length = stream.read(ump, maxLength: MemoryLayout<Self>.size)
        
        guard length != 0 else {
            return nil
        }
        
        precondition(length != -1, "read failed")
        precondition(length == MemoryLayout<Self>.size, "not enough data")
        
        return ump.withMemoryRebound(to: Self.self, capacity: MemoryLayout<Self>.size) {
            $0.pointee
        }
    }
}

extension Data {
    func write(to stream: OutputStream) {
        UInt16(count).write(to: stream)
        if count > 0 {
            _ = withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
                stream.write(bytes, maxLength: count)
            }
        }
    }
    
    static func read(from stream: InputStream) -> Data? {
        guard let u16 = UInt16.read(from: stream) else {
            return nil
        }
        let count = Int(u16)
        guard count > 0 else {
            return Data()
        }
        var data = Data(count: count)
        let length = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Int in
            stream.read(bytes, maxLength: count)
        }
        precondition(length != -1, "read failed")
        precondition(length == count, "not enough data")
        return data
    }
}



