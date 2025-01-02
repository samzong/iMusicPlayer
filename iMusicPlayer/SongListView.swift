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
    @State private var showingDownloadSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(songManager.songs) { song in
                    SongRow(song: song)
                        .onTapGesture {
                            playerManager.playSong(song)
                        }
                }
            }
            .navigationTitle("音乐库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDownloadSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingDownloadSheet) {
                NavigationView {
                    DownloadView()
                        .navigationTitle("下载音乐")
                        .navigationBarItems(trailing: Button("完成") {
                            showingDownloadSheet = false
                        })
                }
            }
        }
        .onAppear {
            songManager.loadLocalSongs()
        }
    }
}

struct SongRow: View {
    let song: Song
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(song.title)
                .font(.headline)
            Text(song.artist)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
