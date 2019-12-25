//
//  ChatView.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

struct ChatView: View {
    let channel: Channel
    
    @ObservedObject private var keyboard = KeyboardObserver.shared
    @ObservedObject private var channelAdapter: ChannelAdapter
    
    @State private var showingSheet = false
    @State private var showingImageSender = false
    @State private var text = ""
    @State private var selectedImage: UIImage!
    
    init(channel: Channel) {
        self.channel = channel
        self.channelAdapter = UIDataAdapter.shared.channelAdapters[channel.id]!
    }
    
    var showingLibraryButton: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        
        let drag = DragGesture().onChanged { _ in
            self.endEditing()
        }
        
        return VStack(spacing: 0) {
            Rectangle().foregroundColor(.clear).frame(height: 1)
            
            List() {
                ForEach(channelAdapter.rows) { data in
                    ChatViewRow(data: data).padding(.top, 3)
                        .scaleEffect(x: 1, y: -1, anchor: .center)
                }
            }
            .onAppear() {
                UITableView.appearance().separatorStyle = .none
                UITableView.appearance().backgroundColor = .clear
                UITableViewCell.appearance().backgroundColor = .clear
            }
            .scaleEffect(x: 1, y: -1, anchor: .center)
            
            HStack {
                HStack(spacing: 0) {
                    TextField("Enter some text", text: self.$text) { self.send() }
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(height: 42).padding(.leading, 10)
                    
                    if !showingLibraryButton {
                        Button(action: { self.send() }) {
                            Image(systemName: "chevron.up.circle.fill")
                                .resizable().foregroundColor(.primary).frame(width: 22, height: 22)
                        }.padding(.all, 10)
                    }
                }
                .background(Color.orange.opacity(0.6))
                .cornerRadius(21)
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.primary, lineWidth: 1))
                
                if showingLibraryButton {
                    Button(action: {
                        self.endEditing()
                        self.showingImageSender = false
                        self.showingSheet.toggle()
                    }) {
                        Image(systemName: "camera.on.rectangle.fill")
                            .imageScale(.medium).foregroundColor(Color.orange.opacity(0.8)).padding(.all, 10)
                    }
                    .sheet(isPresented: $showingSheet) {
                        if self.showingImageSender {
                            ImageSenderView(image: self.selectedImage) { title in
                                self.showingSheet.toggle()
                                self.sendImage(title: title)
                            }
                        } else {
                            ImagePickerView() { image in
                                if let image = image {
                                    self.selectedImage = image
                                    self.showingImageSender.toggle()
                                } else {
                                    self.showingSheet.toggle()
                                }
                            }
                        }
                    }
                }
            }.padding(.all, 6)
            
            Rectangle().foregroundColor(.clear).frame(height: keyboard.height)
        }
        .animation(.easeOut(duration: max(0.15, keyboard.duration)))
        .gesture(drag)
            
        .background(Image(self.channel.image).resizable().aspectRatio(contentMode: .fill).contrast(2.0).saturation(0.0).colorMultiply(.orange).opacity(0.2))
        .navigationBarTitle(Text(self.channel.title), displayMode: .inline)
        
    }
    
    private func send() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            BleConnector.shared.sendText(channel: channel.id, text: trimmedText)
        }
        text = ""
        endEditing()
    }
    
    private func sendImage(title: String) {
        guard let jpegData = self.selectedImage.jpegData(compressionQuality: 1),
            let source = CGImageSourceCreateWithData(jpegData as CFData, nil) else {
                print("failed to create ImageSource with jped data")
                return
        }
        let reducedData = ItemsManager.shared.reduceImage(source: source, maxSize: 1000, compressionQuality: 0.75)
        BleConnector.shared.sendPicture(channel: channel.id, title: title, imageData: reducedData)
    }
    
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

struct ImageSenderView: View {
    let image: UIImage
    let onSend: (_ title: String) -> Void
    
    @ObservedObject private var keyboard = KeyboardObserver.shared
    @State private var title = ""
    var showingSenderButton: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var body: some View {
        ZStack {
            Image("background").resizable().aspectRatio(contentMode: .fill).opacity(0.2)
            
            VStack(spacing: 20) {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fit).cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary, lineWidth: 4))
                    .frame(maxWidth: 200, maxHeight: 200)
                
                HStack(spacing: 0) {
                    TextField("Enter a title", text: $title) { self.send() }
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(height: 42).padding(.leading, 10)
                    
                    if showingSenderButton {
                        Button(action: { self.send() }) {
                            Image(systemName: "chevron.up.circle.fill")
                                .resizable().foregroundColor(.primary).frame(width: 22, height: 22)
                        }.padding(.all, 10)
                    }
                }
                .frame(width: 260)
                .background(Color.orange.opacity(0.6))
                .cornerRadius(21)
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.primary, lineWidth: 1))
                
            }
            .offset(x: 0, y: min(0, (UIScreen.main.bounds.height - 350) / 2 - keyboard.height))
            .animation(.easeOut(duration: max(0.15, keyboard.duration)))
        }
    }
    
    private func send() {
        if showingSenderButton {
            onSend(title.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(channel: channels[0])
    }
}
