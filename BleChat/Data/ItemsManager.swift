//
//  ItemsManager.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import UIKit


class ItemsManager {
    
    static let shared = ItemsManager()
    
    private(set) var items = [Item]()
    
    private let itemsPath: String!
    private let writerQueue = DispatchQueue(label: "com.airfrance-klm.opensource.blechat.writer")
    
    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        itemsPath = directory.appendingPathComponent("items").appendingPathExtension("dat").path
        guard let stream = InputStream(fileAtPath: itemsPath) else {
            return
        }
        stream.open()
        while let item = Item(from: stream) {
            add(item: item)
        }
        stream.close()
    }
    
    func add(item: Item, data: Data) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        add(item: item, data: data, new: true)
    }
    
    private func add(item: Item, data: Data? = nil, new: Bool = false) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        guard !items.contains(item) else {
            return
        }
        items.append(item)
        if new, data != nil {
            write(item: item, data: data!, forceReceivedSize: item.userId == User.shared.userId)
        }
        UIDataAdapter.shared.add(item: item)
    }
    
    func prepare(item: Item) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        guard !items.contains(item) else {
            return
        }
        items.append(item)
        UIDataAdapter.shared.add(item: item)
    }
    
    func update(userId: UserId, index: IndexId, receivedSize: UInt32, data: Data?) -> Bool {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        guard let item = items.first(where: { $0.userId == userId &&  $0.index == index }) else {
            return false
        }
        guard item.receivedSize < receivedSize else {
            return true
        }
        if data != nil, receivedSize == item.size {
            write(item: item, data: data!, forceReceivedSize: true)
        }
        UIDataAdapter.shared.update(item: item, receivedSize: receivedSize)
        return true
    }
    
    private func write(item: Item, data: Data, forceReceivedSize: Bool = false) {
        writerQueue.async {
            guard let stream = OutputStream(toFileAtPath: self.itemsPath, append: true) else {
                print("ERROR: Failed to create OutputStream for PATH: \(self.itemsPath ?? "null")")
                return
            }
            stream.open()
            item.write(to: stream, forceReceivedSize: forceReceivedSize)
            stream.close()
            if item.type == .picture {
                let url = self.imageUrlFor(item: item)
                try? data.write(to: url, options: [.atomic])
                self.createThumbnail(srcURL: url, destURL: self.thumbnailUrlFor(item: item))
            }
        }
    }
    
    private func createThumbnail(srcURL: URL, destURL: URL) {
        let source = CGImageSourceCreateWithURL(srcURL as CFURL, nil)!
        let thumbnailData = reduceImage(source: source, maxSize: 80, compressionQuality: 1.0)
        try? thumbnailData.write(to: destURL, options: [.atomic])
    }
    
    public func reduceImage(source: CGImageSource, maxSize: Int, compressionQuality: CGFloat) -> Data {
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize] as CFDictionary
        let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
        let reduced = UIImage(cgImage: imageReference)
        return reduced.jpegData(compressionQuality: compressionQuality)!
    }
    
    func imageUrlFor(item: Item) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("\(item.userId)_\(item.index)").appendingPathExtension("jpg")
    }
    
    func thumbnailUrlFor(item: Item) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("\(item.userId)_\(item.index)_t").appendingPathExtension("jpg")
    }
    
}
