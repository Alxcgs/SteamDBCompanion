import Foundation

public enum AppLanguageMode: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case ukrainian = "uk"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system:
            return L10n.tr("appearance.system", fallback: "System")
        case .english:
            return L10n.tr("language.english", fallback: "English")
        case .ukrainian:
            return L10n.tr("language.ukrainian", fallback: "Ukrainian")
        }
    }

    public var locale: Locale? {
        switch self {
        case .system:
            return nil
        case .english:
            return Locale(identifier: "en")
        case .ukrainian:
            return Locale(identifier: "uk")
        }
    }
}

public extension AppLanguageMode {
    static func from(rawValue: String) -> AppLanguageMode {
        if let mode = AppLanguageMode(rawValue: rawValue) {
            return mode
        }

        // Backward compatibility with legacy stored values.
        switch rawValue.lowercased() {
        case "english":
            return .english
        case "ukrainian":
            return .ukrainian
        default:
            return .system
        }
    }
}
