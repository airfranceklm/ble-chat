//
//  Item.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation
import BleMesh


typealias IndexId = BleItemIndex
typealias DateTime = UInt64


enum ItemType : Int {
    case identity
    case text
    case picture
}


class Item: ObservableObject {
    var type: ItemType
    var channel: ChannelId
    var userId: UserId
    var index: IndexId
    var date: DateTime
    var text: Data
    var size: UInt32
    @Published var receivedSize: UInt32
    
    static let none = Item()
    
    private init() {
        self.type = .identity
        self.channel = 0
        self.userId = 0
        self.index = 0
        self.date = 0
        self.text = Data()
        self.size = 0
        self.receivedSize = 0
    }
    
    init?(from bleItem: BleItem) {
        guard let headerData = bleItem.headerData else {
            return nil
        }
        let stream = InputStream(data: headerData)
        stream.open()
        guard let rawType = UInt8.read(from: stream),
            let type = ItemType(rawValue: Int(rawType)),
            let channel = UInt8.read(from: stream),
            let date = DateTime.read(from: stream),
            let text = Data.read(from: stream) else {
                stream.close()
                return nil
        }
        self.type = type
        self.channel = Int(channel)
        self.userId = bleItem.terminalId
        self.index = bleItem.itemIndex
        self.date = date
        self.text = text
        self.size = bleItem.size
        self.receivedSize = 0
        stream.close()
    }
    
    init?(from stream: InputStream) {
        guard let rawValue = UInt8.read(from: stream),
            let type = ItemType(rawValue: Int(rawValue)),
            let channel = UInt8.read(from: stream),
            let userId = UserId.read(from: stream),
            let index = IndexId.read(from: stream),
            let date = DateTime.read(from: stream),
            let size = UInt32.read(from: stream),
            let receivedSize = UInt32.read(from: stream),
            let text = Data.read(from: stream) else {
                return nil
        }
        self.type = type
        self.channel = ChannelId(channel)
        self.userId = userId
        self.index = index
        self.date = date
        self.size = size
        self.receivedSize = receivedSize
        self.text = text
    }
    
    func write(to stream: OutputStream, forceReceivedSize: Bool) {
        UInt8(self.type.rawValue).write(to: stream)
        UInt8(self.channel).write(to: stream)
        self.userId.write(to: stream)
        self.index.write(to: stream)
        self.date.write(to: stream)
        self.size.write(to: stream)
        if forceReceivedSize {
            self.size.write(to: stream)
        } else {
            self.receivedSize.write(to: stream)
        }
        self.text.write(to: stream)
    }
    
    private init(type: ItemType, channel: ChannelId, text: String, size: Int? = nil) {
        let textData = text.data(using: .utf8) ?? Data()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let date = DateTime(components.year! * 10000 + components.month! * 100 + components.day!)
        let hour = DateTime(components.hour! * 10000 + components.minute! * 100 + components.second!)
        self.date = date * 1_000_000 + hour
        self.userId = User.shared.userId
        self.index = User.shared.nextIndex()
        self.type = type
        self.channel = channel
        self.text = textData
        self.size = UInt32(size ?? textData.count)
        self.receivedSize = type == .picture ? 0 : self.size
    }
    
    static func identity() -> Item {
        return Item(type: .identity, channel: 0, text: User.shared.displayString)
    }
    
    static func text(_ text: String, onChannel channel: ChannelId) -> Item {
        return Item(type: .text, channel: channel, text: text)
    }
    
    static func picture(_ data: Data, withTitle title: String, onChannel channel: ChannelId) -> Item {
        return Item(type: .picture, channel: channel, text: title, size: data.count)
    }
    
    func bleItem() -> BleItem {
        let stream = OutputStream.toMemory()
        stream.open()
        UInt8(type.rawValue).write(to: stream)
        UInt8(channel).write(to: stream)
        date.write(to: stream)
        if type == .text || type == .identity {
            Data().write(to: stream)
        } else {
            text.write(to: stream)
        }
        let headerData = stream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
        stream.close()
        return BleItem(terminalId: userId, itemIndex: index, previousIndexes: nil, size: size, headerData: headerData)
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.userId == rhs.userId && lhs.index == rhs.index
    }
}
