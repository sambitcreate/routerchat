import SwiftUI

// MARK: - Color Theme
struct ColorTheme {
    // MARK: - Background Colors
    let background: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color

    // MARK: - Content Colors
    let primaryText: Color
    let secondaryText: Color
    let accentColor: Color

    // MARK: - UI Element Colors
    let cardBackground: Color
    let inputBackground: Color
    let divider: Color
    let userMessageBackground: Color
    let assistantMessageBackground: Color
    let navigationBarBackground: Color

    // MARK: - Gradient Colors
    let backgroundGradientStart: Color
    let backgroundGradientEnd: Color
    let overlayGradientStart: Color
    let overlayGradientEnd: Color

    // MARK: - Static Themes
    static let light = ColorTheme(
        // Background Colors
        background: .white,
        secondaryBackground: Color(white: 0.97),
        tertiaryBackground: Color(white: 0.95),

        // Content Colors
        primaryText: .black,
        secondaryText: Color.black.opacity(0.7),
        accentColor: Color(red: 0.35, green: 0.7, blue: 1.0),

        // UI Element Colors
        cardBackground: Color.white.opacity(0.7),
        inputBackground: Color.white.opacity(0.7),
        divider: Color.black.opacity(0.1),
        userMessageBackground: Color(red: 0.35, green: 0.7, blue: 1.0),
        assistantMessageBackground: Color(white: 0.95),
        navigationBarBackground: Color.white.opacity(0.8),

        // Gradient Colors
        backgroundGradientStart: .white,
        backgroundGradientEnd: Color(red: 0.95, green: 0.97, blue: 1.0),
        overlayGradientStart: Color(red: 0.35, green: 0.7, blue: 1.0).opacity(0.05),
        overlayGradientEnd: Color(red: 0.35, green: 0.7, blue: 1.0).opacity(0.02)
    )

    static let dark = ColorTheme(
        // Background Colors
        background: Color(red: 0.05, green: 0.05, blue: 0.05),
        secondaryBackground: Color(white: 0.15),
        tertiaryBackground: Color(white: 0.12),

        // Content Colors
        primaryText: .white,
        secondaryText: Color.white.opacity(0.7),
        accentColor: Color.blue.opacity(0.9),

        // UI Element Colors
        cardBackground: Color(white: 0.15),
        inputBackground: Color(white: 0.15),
        divider: Color.white.opacity(0.1),
        userMessageBackground: Color.blue.opacity(0.8),
        assistantMessageBackground: Color(white: 0.2),
        navigationBarBackground: Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.8),

        // Gradient Colors
        backgroundGradientStart: Color(red: 0.05, green: 0.05, blue: 0.05),
        backgroundGradientEnd: Color(red: 0.1, green: 0.1, blue: 0.15),
        overlayGradientStart: Color.blue.opacity(0.03),
        overlayGradientEnd: Color.blue.opacity(0.01)
    )
}

// MARK: - Environment Key for Theme
struct ThemeKey: EnvironmentKey {
    static let defaultValue: ColorTheme = .light
}

// MARK: - Environment Values Extension
extension EnvironmentValues {
    var colorTheme: ColorTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme
extension View {
    func colorTheme(_ theme: ColorTheme) -> some View {
        environment(\.colorTheme, theme)
    }
}
