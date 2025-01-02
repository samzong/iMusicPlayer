//
//  DownloadView.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import SwiftUI

struct DownloadView: View {
    @State private var txtURL: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("请输入在线 TXT 文件地址", text: $txtURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack(spacing: 40) {
                Button("立即下载") {
                    fetchSongList(from: txtURL)
                }
                .disabled(isLoading)
                
                Button("后台下载") {
                    // 实现后台下载逻辑
                }
                .disabled(true) // 初始版本可以禁用
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    func fetchSongList(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("无效的 URL")
            return
        }
        
        isLoading = true // 禁用按钮，显示加载状态
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false // 恢复按钮可用状态
            }
            
            if let error = error {
                print("下载 TXT 文件出错：\(error)")
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                print("无法解析 TXT 文件内容")
                return
            }
            
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedLine.isEmpty, let songURL = URL(string: trimmedLine) {
                    self.downloadSong(from: songURL)
                }
            }
        }.resume()
    }
    
    func downloadSong(from songURL: URL) {
        let fileName = songURL.lastPathComponent
        let destinationURL = SongManager.shared.getDocumentsDirectory().appendingPathComponent(fileName)
        
        // 检查文件是否已存在
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("\(fileName) 已存在，跳过下载")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: songURL) { tempURL, response, error in
            if let error = error {
                print("下载歌曲出错：\(error)")
                return
            }
            
            guard let tempURL = tempURL else {
                print("临时文件 URL 不存在")
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                DispatchQueue.main.async {
                    let newSong = Song(title: fileName, url: destinationURL)
                    SongManager.shared.addSong(newSong)
                }
                print("\(fileName) 下载完成")
            } catch {
                print("保存歌曲出错：\(error)")
            }
        }
        task.resume()
    }
}
