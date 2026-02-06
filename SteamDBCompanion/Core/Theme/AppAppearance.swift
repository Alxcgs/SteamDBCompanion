import SwiftUI

public enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public extension AppAppearanceMode {
    static func from(rawValue: String) -> AppAppearanceMode {
        AppAppearanceMode(rawValue: rawValue) ?? .system
    }
}
