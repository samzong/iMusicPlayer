import Foundation

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    private init() {}
    
    @Published var downloadQueue: [URL] = []
    @Published var currentDownloadProgress: Float = 0
    @Published var currentDownloadingTitle: String = ""
    @Published var isDownloading: Bool = false
    
    // 下载并解析歌曲列表
    func downloadSongList(from url: URL) async throws -> [URL] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw DownloadError.invalidData
        }
        
        // 解析每行的URL
        return content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .compactMap { URL(string: $0.trimmingCharacters(in: .whitespaces)) }
    }
    
    // 下载单首歌曲
    func downloadSong(from url: URL) async throws -> Song {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DownloadError.downloadFailed
        }
        
        // 获取文件名
        let fileName = url.lastPathComponent
        
        // 保存到本地
        let documentsURL = SongManager.shared.getDocumentsDirectory()
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        // 检查是否已存在同名文件
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try data.write(to: fileURL)
        }
        
        // 创建Song对象
        return Song(title: fileName, url: fileURL)
    }
    
    // 开始批量下载
    func startBatchDownload(urls: [URL]) {
        downloadQueue = urls
        isDownloading = true
        currentDownloadingTitle = ""
        currentDownloadProgress = 0
        
        Task {
            for url in urls {
                if !isDownloading { break } // 允许中断下载
                
                do {
                    currentDownloadingTitle = url.lastPathComponent
                    let song = try await downloadSong(from: url)
                    await MainActor.run {
                        SongManager.shared.addSong(song)
                        if let index = downloadQueue.firstIndex(of: url) {
                            downloadQueue.remove(at: index)
                        }
                        currentDownloadProgress = Float(urls.count - downloadQueue.count) / Float(urls.count)
                    }
                } catch {
                    print("下载失败: \(url.lastPathComponent), 错误: \(error)")
                }
            }
            
            await MainActor.run {
                isDownloading = false
                currentDownloadProgress = 1
                currentDownloadingTitle = ""
            }
        }
    }
    
    func cancelDownload() {
        isDownloading = false
        downloadQueue.removeAll()
        currentDownloadProgress = 0
        currentDownloadingTitle = ""
    }
}

enum DownloadError: Error {
    case invalidURL
    case invalidData
    case downloadFailed
    case fileWriteFailed
} 