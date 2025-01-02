# iMusicPlayer - 简约音乐播放器

[English](README.md) | [中文](README_zh.md)

## 🎵 项目简介

iMusicPlayer 是一款使用 SwiftUI 构建的轻量级、用户友好的音乐播放器应用，同时支持 macOS 和 iOS 平台。它提供了流畅的音乐播放体验，并具备管理和播放音乐集合的基本功能。

### ✨ 功能特点

- **简洁界面**：现代化的UI设计，操作直观
- **音乐库管理**：轻松导入和管理音乐文件
- **基础播放控制**：播放、暂停、上一首/下一首
- **后台播放**：使用其他应用时继续播放音乐
- **系统集成**：支持系统媒体控制和远程控制
- **跨平台**：同时支持 macOS 和 iOS 平台

### 🔧 系统要求

- macOS 11.0+ 或 iOS 14.0+
- Xcode 13.0+ (开发环境)
- Swift 5.5+

### 📦 安装说明

1. 克隆仓库
2. 在 Xcode 中打开 `iMusicPlayer.xcodeproj`
3. 构建并运行项目

### 🚀 使用方法

1. 启动应用
2. 点击"+"按钮导入音乐文件
3. 从列表中选择歌曲开始播放
4. 使用播放器控制栏管理播放

### 🏗 项目结构

```
iMusicPlayer/
├── App/                 # 应用程序入口
├── Models/             # 数据模型
├── Services/           # 业务逻辑服务
├── ViewModels/         # MVVM架构的视图模型
├── Views/              # UI组件
│   ├── Components/     # 可复用UI组件
│   └── Screens/       # 主要应用界面
└── Utils/              # 工具函数
```

### 📱 主要功能模块

1. **音乐管理服务 (SongService)**
   - 音乐文件导入
   - 播放列表管理
   - 音乐文件持久化存储

2. **播放器服务 (PlayerService)**
   - 音频播放控制
   - 后台播放支持
   - 系统媒体控制集成

3. **用户界面**
   - 歌曲列表视图
   - 播放器控制界面
   - 专辑封面显示

### 🤝 贡献指南

欢迎贡献代码或提出建议！如果您想为项目做出贡献，请：

1. Fork 项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详细信息 