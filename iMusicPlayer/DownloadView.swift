//
//  DownloadView.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import SwiftUI

struct DownloadView: View {
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var listURL: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // 示例URL（隐藏实际地址）
    private let exampleURL = "https://img.samzong.me/m.txt"
    
    var body: some View {
        VStack(spacing: 20) {
            // URL 输入
            VStack(alignment: .leading, spacing: 8) {
                TextField("输入歌曲列表URL (.txt)", text: $listURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                HStack(spacing: 20) {
                    // 示例下载按钮
                    Button(action: {
                        listURL = exampleURL
                        startDownload()
                    }) {
                        HStack {
                            Image(systemName: "music.note.list")
                            Text("下载示例歌曲")
                        }
                    }
                    .disabled(downloadManager.isDownloading)
                    
                    // 手动下载按钮
                    if !listURL.isEmpty {
                        Button(action: startDownload) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text(downloadManager.isDownloading ? "下载中..." : "开始下载")
                            }
                        }
                        .disabled(downloadManager.isDownloading)
                    }
                }
            }
            
            if downloadManager.isDownloading {
                VStack(spacing: 10) {
                    // 进度条
                    ProgressView(value: downloadManager.currentDownloadProgress) {
                        HStack {
                            Text("下载进度")
                            Spacer()
                            Text("\(downloadManager.downloadQueue.count) 首歌曲待下载")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } currentValueLabel: {
                        Text("\(Int(downloadManager.currentDownloadProgress * 100))%")
                    }
                    
                    // 当前下载文件名
                    if !downloadManager.currentDownloadingTitle.isEmpty {
                        Text("正在下载: \(downloadManager.currentDownloadingTitle)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 取消按钮
                    Button("取消下载") {
                        downloadManager.cancelDownload()
                    }
                    .foregroundColor(.red)
                }
                .padding()
            }
            
            // 剩余队列
            if !downloadManager.downloadQueue.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("待下载文件:")
                            .font(.headline)
                        Spacer()
                        Text("\(downloadManager.downloadQueue.count) 首")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(downloadManager.downloadQueue, id: \.self) { url in
                                Text(url.lastPathComponent)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            
            Spacer()
        }
        .padding()
        .alert("下载提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func startDownload() {
        guard let url = URL(string: listURL) else {
            alertMessage = "无效的URL"
            showAlert = true
            return
        }
        
        // 开始下载歌曲列表
        Task {
            do {
                let songURLs = try await downloadManager.downloadSongList(from: url)
                if songURLs.isEmpty {
                    await MainActor.run {
                        alertMessage = "歌曲列表为空"
                        showAlert = true
                    }
                } else {
                    downloadManager.startBatchDownload(urls: songURLs)
                }
            } catch {
                await MainActor.run {
                    alertMessage = "下载歌曲列表失败: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
