//
//  SongListView.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import SwiftUI

struct SongListView: View {
    @ObservedObject var songManager = SongManager.shared
    @ObservedObject var playerManager = PlayerManager.shared
    
    var body: some View {
        NavigationView {
            List(songManager.songs) { song in
                Button(action: {
                    playerManager.playSong(song)
                }) {
                    HStack {
                        Text(song.title)
                        Spacer()
                        if playerManager.currentSong == song && playerManager.isPlaying {
                            Image(systemName: "play.fill")
                        }
                    }
                }
            }
            .navigationTitle("歌曲列表")
        }
        .onAppear {
            songManager.loadLocalSongs()
        }
    }
}
