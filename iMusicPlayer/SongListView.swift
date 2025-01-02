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
    @State private var showDeleteAlert = false
    @State private var songToDelete: Song?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(songManager.songs) { song in
                    SongRow(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerManager.playSong(song)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                songToDelete = song
                                showDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
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
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let song = songToDelete {
                        // 如果正在播放这首歌，先停止播放
                        if playerManager.currentSong == song {
                            playerManager.pause()
                        }
                        songManager.deleteSong(song)
                    }
                }
            } message: {
                if let song = songToDelete {
                    Text("确定要删除歌曲「\(song.title)」吗？此操作不可恢复。")
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
    @ObservedObject var playerManager = PlayerManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.headline)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            // 显示当前播放状态
            if playerManager.currentSong == song {
                if playerManager.isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
