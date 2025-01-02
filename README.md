# iMusicPlayer

[English](README.md) | [中文](README_zh.md)

## 🎵 About iMusicPlayer

iMusicPlayer is a lightweight, user-friendly music player application built for macOS and iOS platforms using SwiftUI. It provides a seamless music playback experience with essential features for managing and playing your music collection.

### ✨ Features

- **Simple and Clean Interface**: Modern UI design with intuitive controls
- **Music Library Management**: Easy import and organization of your music files
- **Basic Playback Controls**: Play, pause, next/previous track
- **Background Playback**: Continue playing music while using other apps
- **System Integration**: Support for system media controls and remote control
- **Cross-Platform**: Works on both macOS and iOS

### 🔧 System Requirements

- macOS 11.0+ or iOS 14.0+
- Xcode 13.0+ (for development)
- Swift 5.5+

### 📦 Installation

1. Clone the repository
2. Open `iMusicPlayer.xcodeproj` in Xcode
3. Build and run the project

### 🚀 Usage

1. Launch the app
2. Import music files by clicking the "+" button
3. Select a song from the list to start playing
4. Use the player controls to manage playback

### 🏗 Project Structure

```
iMusicPlayer/
├── App/                 # App entry point
├── Models/             # Data models
├── Services/           # Business logic services
├── ViewModels/         # View models for MVVM
├── Views/              # UI components
│   ├── Components/     # Reusable UI components
│   └── Screens/       # Main app screens
└── Utils/              # Utility functions
```

### 📱 Core Components

1. **Music Management Service (SongService)**
   - Music file import
   - Playlist management
   - Music file persistence

2. **Player Service (PlayerService)**
   - Audio playback control
   - Background playback support
   - System media controls integration

3. **User Interface**
   - Song list view
   - Player control interface
   - Album artwork display

### 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details 