//
//  Channel.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation

typealias ChannelId = Int

struct Channel: Hashable, Codable, Identifiable {
    var id: ChannelId
    var title: String
    var image: String
}

var channels: [Channel] = load()

func load() -> [Channel] {
    let filename = "channels.json"
    let decoder = JSONDecoder()
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil),
        let data = try? Data(contentsOf: file),
        let channels = try? decoder.decode([Channel].self, from: data) else {
            fatalError("Failed to parse \(filename) in main bundle.")
    }
    
    return channels
}
