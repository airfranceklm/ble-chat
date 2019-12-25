//
//  BleConnector.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation
import BleMesh


class BleConnector :NSObject {
    
    static let shared = BleConnector()
    
    private(set) var userId: UserId!
    private let sessionId = UInt64(0x0123456789)
    private var started: Bool
    
    private override init() {
        started = false
        super.init()
        BleLogger.logSeverity = .info
        BleManager.shared.delegate = self
        print("Number of items: \(ItemsManager.shared.items.count)")
    }
    
    func startSession() {
        objc_sync_enter(self)
        
        self.userId = User.shared.userId
        BleManager.shared.start(session: sessionId, terminal: userId)
        
        objc_sync_exit(self)
        
        if User.shared.currentIndex() == 0 {
            sendIdentity()
        }
    }
    
    func stopSession() {
        BleManager.shared.stop()
    }
    
    func sendIdentity() {
        send(item: Item.identity())
    }
    
    func sendText(channel: ChannelId, text: String) {
        send(item: Item.text(text, onChannel: channel))
    }
    
    func sendPicture(channel: ChannelId, title: String, imageData: Data) {
        send(item: Item.picture(imageData, withTitle: title, onChannel: channel), data: imageData)
    }
    
    private func send(item: Item, data: Data? = nil) {
        ItemsManager.shared.add(item: item, data: data ?? Data())
        
        if started {
            BleManager.shared.broadcast(item: item.bleItem())
        }
        
    }
}

extension BleConnector : BleManagerDelegate {
    var bleItems: [BleItem] {
        ItemsManager.shared.items.filter{ $0.receivedSize == $0.size || $0.userId == userId }.map{ $0.bleItem() }
    }
    
    func bleManagerItemSliceFor(terminalId: BleTerminalId, index: BleItemIndex, offset: UInt32, length: UInt32) -> Data? {
        var slice: Data? = nil
        if let item = ItemsManager.shared.items.first(where: { $0.userId == terminalId && $0.index == index }) {
            if item.type == .text || item.type == .identity {
                slice = item.text.subdata(in: Int(offset)..<min(Int(offset + length), item.text.count))
            } else if let handle = try? FileHandle(forReadingFrom: ItemsManager.shared.imageUrlFor(item: item)) {
                handle.seek(toFileOffset: UInt64(offset))
                slice = handle.readData(ofLength: Int(length))
                handle.closeFile()
            }
        }
        return slice
    }
    
    func bleManagerDidReceive(item: BleItem, data: Data) {
        if !ItemsManager.shared.update(userId: item.terminalId, index: item.itemIndex, receivedSize: item.size, data: data) {
            guard let newItem = Item(from: item), newItem.type != .picture else {
                return
            }
            newItem.text = newItem.type == .text || newItem.type == .identity ? data : newItem.text
            newItem.receivedSize = newItem.size
            ItemsManager.shared.add(item: newItem, data: newItem.type == .text ? Data() : data)
        }
        
    }
    
    func bleManagerIsReceiving(item: BleItem, totalSizeReceived: UInt32) {
        if !ItemsManager.shared.update(userId: item.terminalId, index: item.itemIndex, receivedSize: totalSizeReceived, data: nil) {
            guard let newItem = Item(from: item), newItem.type == .picture, totalSizeReceived == 0 else {
                return
            }
            ItemsManager.shared.prepare(item: newItem)
        }
    }
    
    func bleManagerIsSending(item: BleItem, totalSizeSent: UInt32) {
        _ = ItemsManager.shared.update(userId: item.terminalId, index: item.itemIndex, receivedSize: totalSizeSent, data: nil)
    }
    
    func bleManagerDidStart() {
        started = true
    }
    
    func bleManagerDidStop() {
        started = false
    }
}

