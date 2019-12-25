//
//  AvatarPickerView.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

struct AvatarPickerView: View {
    let names = ["bat", "bear", "bee", "bird", "bug", "butterfly", "camel", "cat", "cheetah", "cobra", "cow", "crocodile", "dinosaur", "dog", "dolphin", "dove", "duck", "eagle", "elephant", "fish", "flamingo", "fox", "frog", "giraffe", "gorilla", "hen", "horse", "kangaroo", "koala", "leopard", "lion", "monkey", "mouse", "panda", "parrot", "penguin", "shark", "sheep", "spider", "squirrel", "starfish", "tiger", "turtle", "wolf", "zebra"]

    @ObservedObject private var keyboard = KeyboardObserver.shared
    
    @State var showingAvatars = false
    @State var avatar = User.shared.avatar
    @State var nickname = User.shared.nickname
    
    let imageSize = CGFloat(70)
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 20) {
                ZStack {
                    Color.primary.clipShape(Circle())
                    
                    Button(action: { UIApplication.shared.endEditing(); self.showingAvatars.toggle() }) {
                        Image(avatar).resizable().renderingMode(.original)
                    }
                    .padding(.all, 4)
                }
                .frame(width: 208, height: 208)
                
                if showingAvatars {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(names, id: \.self) { name in
                                GeometryReader { geometry in
                                    Image(name).resizable().modifier(EffectModifier(geometry, self.imageSize)).onTapGesture {
                                        self.showingAvatars = false
                                        self.avatar = name
                                        self.save()
                                    }
                                }.frame(width: self.imageSize, height: self.imageSize)
                            }
                        }
                    }.animation(.none)
                }
                
                TextField("Enter a nickname", text: $nickname) {
                    self.save()
                }
                .multilineTextAlignment(.center)
                .foregroundColor(Color(UIColor.systemBackground))
                .frame(width: 260, height: 42).padding([.leading, .trailing], 10)
                .background(Color.orange.opacity(0.6))
                .cornerRadius(21)
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.primary, lineWidth: 1))
                .padding(.top, 40)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    self.showingAvatars = false
                }
            }
            .offset(x: 0, y: min(0, (UIScreen.main.bounds.height - 350) / 2 - keyboard.height))
            .animation(.easeOut(duration: max(0.15, keyboard.duration)))
            
            VStack {
                Spacer()
                WebLink(items: [
                    ("Icons designed by", nil),
                    ("Pixel perfect", "https://www.flaticon.com/authors/pixel-perfect"),
                    ("from", nil),
                    ("www.flaticon.com", "https://www.flaticon.com/")
                ])
            }
        }
    }
    
    func save() {
        User.shared.update(nickname: nickname, avatar: avatar)
        BleConnector.shared.sendIdentity()
    }
}

struct WebLink: View {
    struct Element: Identifiable {
        var id: Int
        let label: String
        let url: URL?
        let weight: Font.Weight
        let color: Color
    }
    
    private let items: [Element]
    
    init(items: [(label: String, path: String?)]) {
        var elements = [Element]()
        for (index,item) in items.enumerated() {
            if let path = item.path, let url = URL(string: path) {
                elements.append(Element(id: index, label: item.label, url: url, weight: .bold, color: .orange))
            } else {
                elements.append(Element(id: index, label: item.label, url: nil, weight: .light, color: .primary))
            }
        }
        self.items = elements
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(items) { item in
                Button(action: {
                    if let url = item.url {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(item.label)
                        .font(.system(size: 9, weight: item.weight, design: .monospaced))
                        .disabled(item.url == nil)
                        .foregroundColor(item.color)
                }
            }
        }
    }
}

struct EffectModifier: ViewModifier {
    private var ratio: Double!
    
    init(_ geometry: GeometryProxy, _ imageSize: CGFloat) {
        let length = (UIScreen.main.bounds.width - imageSize) / 2
        let minX = geometry.frame(in: .global).minX
        let x = (min(2 * length, max(0, minX)) - length).magnitude
        ratio = Double(x / length)
    }
    
    func effect(minValue: Double) -> Double {
        return 1 - ratio * (1 - minValue)
    }
    
    func body(content: Content) -> some View {
        content
            .saturation(effect(minValue: 0.3))
            .opacity(effect(minValue: 0.2))
            .scaleEffect(CGFloat(effect(minValue: 0.7)))
    }
}

struct AvatarPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarPickerView()
    }
}
