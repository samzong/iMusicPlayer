import Foundation

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    private init() {}
    
    @Published var downloadQueue: [URL] = []
    @Published var currentDownloadProgress: Float = 0
    @Published var currentDownloadingTitle: String = ""
    @Published var isDownloading: Bool = false
    @Published var skippedSongs: [(title: String, reason: String)] = []
    
    // 下载并解析歌曲列表
    func downloadSongList(from url: URL) async throws -> [URL] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw DownloadError.invalidData
        }
        
        // 解析每行的URL，只保留 HTTPS URLs
        let allURLs = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .compactMap { URL(string: $0.trimmingCharacters(in: .whitespaces)) }
        
        // 过滤非 HTTPS URLs
        let httpsURLs = allURLs.filter { $0.scheme?.lowercased() == "https" }
        
        // 记录被跳过的 HTTP URLs
        let httpURLs = allURLs.filter { $0.scheme?.lowercased() == "http" }
        skippedSongs.append(contentsOf: httpURLs.map { 
            ($0.lastPathComponent, "仅支持 HTTPS 链接")
        })
        
        return httpsURLs
    }
    
    // 下载单首歌曲
    func downloadSong(from url: URL) async throws -> Song {
        // 验证是否为 HTTPS
        guard url.scheme?.lowercased() == "https" else {
            throw DownloadError.httpNotAllowed
        }
        
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
        skippedSongs.removeAll()
        
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
                } catch DownloadError.httpNotAllowed {
                    await MainActor.run {
                        skippedSongs.append((url.lastPathComponent, "仅支持 HTTPS 链接"))
                        if let index = downloadQueue.firstIndex(of: url) {
                            downloadQueue.remove(at: index)
                        }
                        currentDownloadProgress = Float(urls.count - downloadQueue.count) / Float(urls.count)
                    }
                } catch {
                    await MainActor.run {
                        skippedSongs.append((url.lastPathComponent, "下载失败: \(error.localizedDescription)"))
                        if let index = downloadQueue.firstIndex(of: url) {
                            downloadQueue.remove(at: index)
                        }
                        currentDownloadProgress = Float(urls.count - downloadQueue.count) / Float(urls.count)
                    }
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
        skippedSongs.removeAll()
    }
}

enum DownloadError: Error {
    case invalidURL
    case invalidData
    case downloadFailed
    case fileWriteFailed
    case httpNotAllowed
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidData:
            return "无效的数据"
        case .downloadFailed:
            return "下载失败"
        case .fileWriteFailed:
            return "文件写入失败"
        case .httpNotAllowed:
            return "仅支持 HTTPS 链接"
        }
    }
} 