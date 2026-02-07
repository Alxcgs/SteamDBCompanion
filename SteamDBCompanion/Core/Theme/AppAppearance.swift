import SwiftUI

public enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return L10n.tr("appearance.system", fallback: "System")
        case .light: return L10n.tr("appearance.light", fallback: "Light")
        case .dark: return L10n.tr("appearance.dark", fallback: "Dark")
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
