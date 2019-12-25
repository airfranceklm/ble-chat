//
//  ChatViewRow.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

struct ChatViewRow: View {
    let data: ChatRowData
    
    @ObservedObject private var dataAdapter = UIDataAdapter.shared
    @ObservedObject private var item: Item
    @State private var showingImage = false
    @State private var shownImage: Image!
    
    init(data: ChatRowData) {
        self.data = data
        self.item = data.item ?? Item.none
    }
    
    private let TEXTS_COLOR = Color.primary.opacity(0.75)
    private let HOURS_COLOR = Color.primary.opacity(0.5)
    private let BOLD_FONT = Font.system(size: 15, weight: .bold, design: .rounded)
    private let LIGHT_FONT = Font.system(size: 15, weight: .regular, design: .rounded)
    private let SMALL_FONT = Font.system(size: 10, weight: .regular, design: .rounded)
    private let MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private let DAYS = [1: "st", 2: "nd", 3: "rd", 21: "st", 22: "nd", 23: "rd", 31: "st"]
    
    var body: some View {
        Group {
            if data.date != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(data.date!)).foregroundColor(TEXTS_COLOR).font(BOLD_FONT)
                    Rectangle().background(TEXTS_COLOR).frame(height: 0.5)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        TEXTS_COLOR.clipShape(Circle())
                        Image(user(data.item!).avatar).resizable().padding(.all, 2)
                    }.frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user(data.item!).nickname).foregroundColor(TEXTS_COLOR).font(BOLD_FONT)
                            Text(formatHour(data.item!)).foregroundColor(HOURS_COLOR).font(LIGHT_FONT)
                        }
                        Text(formatText(data.item!)).foregroundColor(TEXTS_COLOR).font(LIGHT_FONT)
                        if data.item!.type == .picture {
                            HStack(alignment: .top, spacing: 12) {
                                thumbnail(data.item!).resizable().aspectRatio(contentMode: .fit)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.6), lineWidth: 1))
                                    .frame(maxWidth: 40, maxHeight: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(imageTitle(data.item!)).foregroundColor(TEXTS_COLOR).font(BOLD_FONT)
                                    Text(receivedSize(data.item!)).foregroundColor(TEXTS_COLOR).font(SMALL_FONT)
                                }
                            }
                            .onTapGesture {
                                if let image = self.image(self.item) {
                                    self.shownImage = image
                                    self.showingImage = true
                                }
                            }
                            .sheet(isPresented: $showingImage) {
                                self.shownImage.resizable().aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func user(_ item: Item) -> (nickname: String, avatar: String) {
        if let user = dataAdapter.users[item.userId] {
            return (user.nickname, user.avatar)
        }
        let itemUser = User(item: item)
        return (itemUser.nickname, itemUser.avatar)
    }
    
    func formatDate(_ date: DateTime) -> String {
        let day = Int(date % 100)
        let month = Int((date / 100) % 100)
        let year = Int(date / 10000)
        return "\(MONTHS[month-1]) \(day)\(DAYS[day] ?? "th"), \(year)"
    }
    
    func formatHour(_ item: Item) -> String {
        return String(format: "%d:%02d", (item.date / 10000) % 100, (item.date / 100) % 100)
    }
    
    func formatText(_ item: Item) -> String {
        if item.type == .text {
            return String(bytes: item.text, encoding: .utf8) ?? ">> error <<"
        } else {
            return item.receivedSize == item.size ? "Uploaded image" : "Uploading image"
        }
    }
    
    func thumbnail(_ item: Item) -> Image {
        if item.receivedSize != item.size && item.userId != User.shared.userId {
            return Image("unknown_image")
        }
        let thumbnailPath = ItemsManager.shared.thumbnailUrlFor(item: item).path
        let uiImage = UIImage(contentsOfFile: thumbnailPath)
        return uiImage == nil ? Image("unknown_image") : Image(uiImage: uiImage!)
    }
    
    func image(_ item: Item) -> Image? {
        let imagePath = ItemsManager.shared.imageUrlFor(item: item).path
        let uiImage = UIImage(contentsOfFile: imagePath)
        return uiImage == nil ? nil : Image(uiImage: uiImage!)
    }
    
    func imageTitle(_ item: Item) -> String {
        return String(bytes: item.text, encoding: .utf8) ?? ">> error <<"
    }
    
    func receivedSize(_ item: Item) -> String {
        let size = NumberFormatter.localizedString(from: NSNumber(value: item.size), number: NumberFormatter.Style.decimal)
        let received = NumberFormatter.localizedString(from: NSNumber(value: item.receivedSize), number: NumberFormatter.Style.decimal)
        return size == received ? "\(size) bytes" : "\(received) of \(size) bytes"
    }
}
