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
    
    @Published var songs: [Song] = [] {
        didSet {
            print("SongManager: 歌曲列表更新，当前有 \(songs.count) 首歌曲")
            NotificationCenter.default.post(name: NSNotification.Name("SongsDidChange"), object: nil)
        }
    }
    
    private init() {
        print("SongManager: 开始初始化")
        DispatchQueue.main.async { [weak self] in
            self?.loadLocalSongs()
        }
    }
    
    func loadLocalSongs() {
        print("SongManager: 开始加载本地歌曲")
        let fileManager = FileManager.default
        let documentsURL = getDocumentsDirectory()
        print("SongManager: 文档目录路径 - \(documentsURL.path)")
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print("SongManager: 目录中的所有文件 - \(files.map { $0.lastPathComponent })")
            
            let audioFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "mp3" || ext == "aac" || ext == "wav"
            }
            
            print("SongManager: 找到 \(audioFiles.count) 个音频文件")
            
            var loadedSongs: [Song] = []
            for url in audioFiles {
                do {
                    // 验证文件是否真实存在且可访问
                    guard fileManager.fileExists(atPath: url.path),
                          fileManager.isReadableFile(atPath: url.path) else {
                        print("SongManager: 文件不存在或不可读 - \(url.lastPathComponent)")
                        continue
                    }
                    
                    let filename = url.deletingPathExtension().lastPathComponent
                    let components = filename.components(separatedBy: " - ")
                    
                    var song: Song
                    if components.count > 1 {
                        song = Song(title: components[1], url: url)
                        song.artist = components[0]
                    } else {
                        song = Song(title: filename, url: url)
                    }
                    
                    print("SongManager: 成功加载歌曲 - \(song.title) (艺术家: \(song.artist))")
                    loadedSongs.append(song)
                } catch {
                    print("SongManager: 加载单个歌曲失败 - \(url.lastPathComponent), 错误: \(error)")
                }
            }
            
            print("SongManager: 成功加载 \(loadedSongs.count) 首歌曲")
            DispatchQueue.main.async {
                self.songs = loadedSongs
            }
            
        } catch {
            print("SongManager: 读取本地歌曲目录出错：\(error)")
        }
    }
    
    func addSong(_ song: Song) {
        print("SongManager: 尝试添加歌曲 - \(song.title)")
        guard FileManager.default.fileExists(atPath: song.url.path) else {
            print("SongManager: 添加失败 - 文件不存在")
            return
        }
        
        if !songs.contains(song) {
            DispatchQueue.main.async {
                self.songs.append(song)
            }
            print("SongManager: 歌曲添加成功")
        } else {
            print("SongManager: 歌曲已存在，跳过添加")
        }
    }
    
    func deleteSong(_ song: Song) {
        print("SongManager: 尝试删除歌曲 - \(song.title)")
        do {
            // 从文件系统删除文件
            if FileManager.default.fileExists(atPath: song.url.path) {
                try FileManager.default.removeItem(at: song.url)
                print("SongManager: 文件删除成功")
            } else {
                print("SongManager: 文件已不存在")
            }
            
            // 从列表中移除
            DispatchQueue.main.async {
                if let index = self.songs.firstIndex(of: song) {
                    self.songs.remove(at: index)
                    print("SongManager: 歌曲从列表中移除成功")
                }
            }
        } catch {
            print("SongManager: 删除歌曲失败：\(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
