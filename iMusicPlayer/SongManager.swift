//
//  SongManager.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import Foundation
import AVFoundation

class SongManager: ObservableObject {
    static let shared = SongManager()
    private init() {}
    
    @Published var songs: [Song] = []
    
    func loadLocalSongs() {
        // 加载本地歌曲文件
        let fileManager = FileManager.default
        let documentsURL = getDocumentsDirectory()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let audioFiles = files.filter { $0.pathExtension == "mp3" || $0.pathExtension == "aac" || $0.pathExtension == "wav" }
            
            songs = audioFiles.map { url in
                var song = Song(title: url.lastPathComponent, url: url)
                // 可选：从文件名中提取艺术家信息
                let filename = url.deletingPathExtension().lastPathComponent
                let components = filename.components(separatedBy: " - ")
                if components.count > 1 {
                    song.artist = components[0]
                }
                return song
            }
        } catch {
            print("读取本地歌曲出错：\(error)")
        }
    }
    
    func addSong(_ song: Song) {
        if !songs.contains(song) {
            songs.append(song)
        }
    }
    
    func deleteSong(_ song: Song) {
        do {
            // 从文件系统删除文件
            try FileManager.default.removeItem(at: song.url)
            // 从列表中移除
            if let index = songs.firstIndex(of: song) {
                songs.remove(at: index)
            }
        } catch {
            print("删除歌曲失败：\(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
