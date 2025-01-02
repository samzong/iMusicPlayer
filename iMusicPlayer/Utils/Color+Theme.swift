import SwiftUI

struct ThemeColors {
    let background: Color
    let accent: Color
    let gradient: LinearGradient
    
    init(colorScheme: ColorScheme) {
        // 背景色
        self.background = colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
        
        // 强调色
        self.accent = colorScheme == .dark 
            ? Color(red: 0.4, green: 0.678, blue: 1.0) 
            : Color(red: 0.0, green: 0.478, blue: 1.0)
        
        // 渐变背景
        self.gradient = LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark
                    ? [Color(white: 0.1), Color(white: 0.05)]
                    : [Color(white: 0.95), Color(white: 0.90)]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ThemeProvider: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.themeColors, ThemeColors(colorScheme: colorScheme))
    }
}

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = ThemeColors(colorScheme: .light)
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

extension View {
    func withTheme() -> some View {
        modifier(ThemeProvider())
    }
} 