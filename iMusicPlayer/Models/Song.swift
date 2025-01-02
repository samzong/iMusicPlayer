import Foundation
import UIKit

struct Song: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    let url: URL
    
    enum CodingKeys: String, CodingKey {
        case id, title, url
    }
    
    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
} 