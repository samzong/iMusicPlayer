import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    
    var url: URL {
        // 直接使用 Documents 目录，不创建子文件夹
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(title).mp3")
    }
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
} 