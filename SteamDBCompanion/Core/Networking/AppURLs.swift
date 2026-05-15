import Foundation

public enum AppURLs {
    public static let steamDB = URL(staticString: "https://steamdb.info")
    public static let steamStore = URL(staticString: "https://store.steampowered.com")
    public static let steamDBSearch = URL(staticString: "https://steamdb.info/search/")
    public static let steamStoreLogin = URL(staticString: "https://store.steampowered.com/login/")
    public static let steamStoreWishlist = URL(staticString: "https://store.steampowered.com/wishlist/")
    public static let steamStoreNews = URL(staticString: "https://store.steampowered.com/news/")
    public static let steamStoreNewsFeed = URL(staticString: "https://store.steampowered.com/feeds/news.xml")
    public static let steamStoreUserData = URL(staticString: "https://store.steampowered.com/dynamicstore/userdata/")
    public static let steamStoreFeaturedCategories = URL(staticString: "https://store.steampowered.com/api/featuredcategories/")
    public static let steamStoreSearch = URL(staticString: "https://store.steampowered.com/api/storesearch/")
    public static let steamStoreSearchResults = URL(staticString: "https://store.steampowered.com/search/results/")
    public static let steamStoreAppDetails = URL(staticString: "https://store.steampowered.com/api/appdetails")
    public static let steamCurrentPlayers = URL(staticString: "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/")
    public static let steamAppNews = URL(staticString: "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/")
    public static let steamChartsApp = URL(staticString: "https://steamcharts.com/app/")
    public static let invalidGateway = URL(staticString: "https://invalid.local")

    public static func steamDB(path: String) -> URL {
        let normalizedPath: String
        if path.isEmpty {
            normalizedPath = "/"
        } else if path.hasPrefix("/") {
            normalizedPath = path
        } else {
            normalizedPath = "/\(path)"
        }
        guard let url = URL(string: normalizedPath, relativeTo: steamDB)?.absoluteURL else {
            preconditionFailure("Invalid SteamDB path: \(path)")
        }
        return url
    }

    public static func steamStoreApp(id: Int) -> URL {
        steamStore
            .appending(path: "app")
            .appending(path: String(id))
    }
}

private extension URL {
    init(staticString: String) {
        guard let url = URL(string: staticString) else {
            preconditionFailure("Invalid static URL: \(staticString)")
        }
        self = url
    }
}
