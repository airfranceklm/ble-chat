//
//  User.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import Foundation
import BleMesh

typealias UserId = BleTerminalId


class User: ObservableObject {
    static let shared = User()
    
    private(set) var userId: UserId
    private(set) var index: IndexId
    @Published private(set) var nickname: String
    @Published private(set) var avatar: String
    
    var displayString: String { "\(avatar)\n\(nickname)" }
    
    private let path: String!
    private var userKey: String!
    
    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        path = directory.appendingPathComponent("user").appendingPathExtension("dat").path
        userId = UserId(0)
        let uuid = UUID().uuidString.data(using: .ascii)!
        for i in 0..<uuid.count {
            userId = 31 &* userId &+ UserId(uuid[i])
        }
        nickname = "user\(userId % 1_000_000)"
        avatar = "unknown_user"
        index = 0
        if !load() {
            print("Initiating user with default values")
            save()
        }
        userKey = "UserIndex\(userId)"
    }
    
    init(item: Item) {
        self.path = nil
        self.userKey = nil
        self.userId = item.userId
        self.nickname = "user\(item.userId % 1_000_000)"
        self.avatar = "unknown_user"
        self.index = 0
        if item.type == .identity, let text = String(bytes: item.text, encoding: .utf8) {
            let userInfo = text.split(separator: "\n")
            if userInfo.count == 2 {
                self.avatar = String(userInfo[0])
                self.nickname = String(userInfo[1])
                self.index = item.index
            }
        }
    }
    
    func update(nickname: String, avatar: String) {
        self.nickname = nickname
        self.avatar = avatar
        save()
    }
    
    func currentIndex() -> IndexId {
        guard let key = userKey else {
            return 0
        }
        objc_sync_enter(self)
        let index = IndexId(UserDefaults.standard.integer(forKey: key))
        objc_sync_exit(self)
        return index
    }
    
    func nextIndex() -> IndexId {
        guard let key = userKey else {
            return 0
        }
        objc_sync_enter(self)
        let index = IndexId(UserDefaults.standard.integer(forKey: key))
        let nextIndex = index + 1
        UserDefaults.standard.set(Int(nextIndex), forKey: key)
        objc_sync_exit(self)
        return nextIndex
    }
    
    private func load() -> Bool {
        guard FileManager.default.fileExists(atPath: path), let stream = InputStream(fileAtPath: path) else {
            print("ERROR: Failed to create InputStream for PATH: \(path ?? "nil")")
            return false
        }
        stream.open()
        guard let userId = UserId.read(from: stream),
            let nicknameData = Data.read(from: stream),
            let nickname = String(bytes: nicknameData, encoding: .utf8),
            let avatarData = Data.read(from: stream),
            let avatar = String(bytes: avatarData, encoding: .utf8) else {
                stream.close()
                print("ERROR: Failed to read user details")
                return false
        }
        stream.close()
        self.userId = userId
        self.nickname = nickname
        self.avatar = avatar
        return true
    }
    
    private func save() {
        guard let stream = OutputStream(toFileAtPath: path, append: false) else {
            print("ERROR: Failed to create OutputStream for PATH: \(path ?? "nil")")
            return
        }
        stream.open()
        userId.write(to: stream)
        nickname.data(using: .utf8)!.write(to: stream)
        avatar.data(using: .utf8)!.write(to: stream)
        stream.close()
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.userId == rhs.userId
    }
}
