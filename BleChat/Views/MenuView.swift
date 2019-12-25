//
//  MenuView.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

fileprivate let CHANNEL_ROW_PADDING = CGFloat(10)

struct MenuView: View {
    
    @State var showingProfile = false
    
    var profileButton: some View {
        Button(action: { self.showingProfile.toggle() }) {
            Image(systemName: "person.crop.circle").imageScale(.large).padding()
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(channels) { channel in
                            NavigationLink(destination: ChatView(channel: channel)) {
                                ChannelRowView(channel: channel)
                            }
                        }
                        .frame(height: CHANNEL_ROW_PADDING + geometry.size.width / 2)
                    }
                }
                .navigationBarTitle(Text("Channels"))
                .navigationBarItems(trailing: self.profileButton)
                .sheet(isPresented: self.$showingProfile) {
                    ZStack {
                        Image("background").resizable().aspectRatio(contentMode: .fill).opacity(0.2)
                        AvatarPickerView()
                    }
                }
            }
            
            ChatView(channel: channels[0])
        }
        .accentColor(Color.orange.opacity(0.8))
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .onAppear() {
            BleConnector.shared.startSession()
        }
    }
}

struct ChannelRowView: View {
    let channel: Channel
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(self.channel.image)
                .renderingMode(.original)
                .resizable()
                .saturation(0.2)
                .cornerRadius(30)
                .padding(CHANNEL_ROW_PADDING)
                .rotationEffect(Angle(degrees: Double(Int.random(in: -3...3))))

            VStack(alignment: .leading) {
                Text(self.channel.title).font(.system(size: 24)).fontWeight(.heavy).tracking(-3).foregroundColor(.orange).shadow(color: .black, radius: 2).padding([.top, .leading], 30).opacity(0.7)
                Rectangle().foregroundColor(Color(UIColor.systemBackground)).frame(height: 3)
            }
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
