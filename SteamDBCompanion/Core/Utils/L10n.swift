import Foundation

public enum L10n {
    public static func tr(_ key: String, fallback: String) -> String {
        let value = localizedBundle().localizedString(forKey: key, value: key, table: nil)
        return value == key ? fallback : value
    }

    private static func localizedBundle() -> Bundle {
        let raw = UserDefaults.standard.string(forKey: "appLanguageMode") ?? "system"
        let mode: String
        switch raw.lowercased() {
        case "en", "english":
            mode = "en"
        case "uk", "ukrainian":
            mode = "uk"
        default:
            mode = "system"
        }

        guard mode == "en" || mode == "uk" else {
            return .main
        }
        guard let path = Bundle.main.path(forResource: mode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
