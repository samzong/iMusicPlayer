//
//  Song.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import Foundation
import UIKit

struct Song: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let url: URL
    
    // 可选字段，后续完善
    var artist: String = "未知艺术家"
    var albumTitle: String? = nil
    var duration: TimeInterval = 0
    var artworkURL: URL? = nil
    var artwork: UIImage? = nil
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
