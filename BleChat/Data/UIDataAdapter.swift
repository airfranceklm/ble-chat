//
//  UIDataAdapter.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation


struct ChatRowData: Identifiable {
    let id: Int64
    let date: DateTime?
    let item: Item?
    
    init(date: DateTime) {
        self.id = ChatRowData.idFor(date: date)
        self.date = date / 1_000_000
        self.item = nil
    }
    
    init(item: Item) {
        self.id = ChatRowData.idFor(item: item)
        self.date = nil
        self.item = item
    }
    
    static func idFor(date: DateTime) -> Int64 {
        return Int64(date / 1_000_000)
    }
    
    static func idFor(item: Item) -> Int64 {
        return Int64("\(item.userId)\n\(item.index)".hashValue)
    }
}


class UIDataAdapter: ObservableObject {
    static let shared = UIDataAdapter()

    @Published private(set) var users = [UserId : User]()
    private(set) var channelAdapters = [ChannelId : ChannelAdapter]()
    
    private init() {
        for channel in channels {
            channelAdapters[channel.id] = ChannelAdapter()
        }
    }
    
    func add(item: Item) {
        DispatchQueue.main.async {
            if item.type == .identity {
                if (self.users[item.userId]?.index ?? 0) < item.index {
                    self.users[item.userId] = User(item: item)
                }
            } else {
                self.channelAdapters[item.channel]?.add(item)
            }
        }
    }
    
    func update(item: Item, receivedSize: UInt32) {
        DispatchQueue.main.async {
            self.channelAdapters[item.channel]?.update(item: item, receivedSize: receivedSize)
        }
    }
}

class ChannelAdapter: ObservableObject {
    @Published private(set) var rows = [ChatRowData]()
    
    fileprivate func add(_ item: Item) {
        let dateId = ChatRowData.idFor(date: item.date)
        if var index = rows.firstIndex(where: { $0.id == dateId }) {
            while index > 0 {
                let row = rows[index - 1]
                if row.item == nil || row.item!.date > item.date {
                    break
                }
                index -= 1
            }
            rows.insert(ChatRowData(item: item), at: index)
        } else {
            var index = 0
            let date = item.date / 1_000_000
            for dateRow in rows.filter({ $0.date != nil }).reversed() {
                if date < dateRow.date! {
                    index = rows.firstIndex(where: { $0.id == dateRow.id })!
                    break
                }
            }
            rows.insert(ChatRowData(date: item.date), at: index)
            rows.insert(ChatRowData(item: item), at: index)
        }
    }
    
    fileprivate func update(item: Item, receivedSize: UInt32) {
        let itemId = ChatRowData.idFor(item: item)
        if let existingItem = self.rows.first(where: { $0.id == itemId }) {
            existingItem.item!.receivedSize = receivedSize
        }
    }
}
