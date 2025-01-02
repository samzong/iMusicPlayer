//
//  ContentView.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PlayerView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("播放器")
                }
            
            SongListView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("音乐库")
                }
        }
    }
}
