import Foundation

public final class RouteRegistry: RouteResolver {
    public static let shared = RouteRegistry()

    public let descriptors: [RouteDescriptor]

    public init(descriptors: [RouteDescriptor] = RouteRegistry.defaultDescriptors) {
        self.descriptors = descriptors
    }

    public func resolve(url: URL) -> RouteResolution {
        let fallbackPath = url.path.isEmpty ? "/" : url.path
        let path = Self.normalizePath(fallbackPath)
        return resolve(path: path)
    }

    public func resolve(path: String) -> RouteResolution {
        let normalizedPath = Self.normalizePath(path)

        if let exact = descriptors.first(where: { Self.normalizePath($0.path) == normalizedPath }) {
            return RouteResolution(descriptor: exact, normalizedPath: normalizedPath)
        }

        if let parameterized = descriptors.first(where: { Self.matches(routePattern: $0.path, candidatePath: normalizedPath) }) {
            return RouteResolution(descriptor: parameterized, normalizedPath: normalizedPath)
        }

        return RouteResolution(
            descriptor: RouteDescriptor(
                path: normalizedPath,
                title: "Web Fallback",
                mode: .webFallback,
                group: .unknown
            ),
            normalizedPath: normalizedPath
        )
    }

    private static func normalizePath(_ rawPath: String) -> String {
        if rawPath.isEmpty { return "/" }
        let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "/" }

        if let url = URL(string: trimmed), let host = url.host, !host.isEmpty {
            let extracted = url.path.isEmpty ? "/" : url.path
            return normalizePath(extracted)
        }

        let withLeadingSlash = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        if withLeadingSlash.count > 1, withLeadingSlash.hasSuffix("/") {
            return String(withLeadingSlash.dropLast())
        }
        return withLeadingSlash
    }

    private static func matches(routePattern: String, candidatePath: String) -> Bool {
        let patternComponents = normalizePath(routePattern).split(separator: "/")
        let candidateComponents = normalizePath(candidatePath).split(separator: "/")

        guard patternComponents.count == candidateComponents.count else {
            return false
        }

        for index in patternComponents.indices {
            let patternItem = patternComponents[index]
            let candidateItem = candidateComponents[index]
            if patternItem.hasPrefix(":") {
                continue
            }
            if patternItem != candidateItem {
                return false
            }
        }
        return true
    }
}

public extension RouteRegistry {
    static let defaultDescriptors: [RouteDescriptor] = [
        RouteDescriptor(path: "/", title: "Home", mode: .native, group: .home),
        RouteDescriptor(path: "/search", title: "Search", mode: .native, group: .search),
        RouteDescriptor(path: "/instantsearch", title: "Instant Search", mode: .native, group: .search),
        RouteDescriptor(path: "/app/:id", title: "Game Details", mode: .native, group: .app),
        RouteDescriptor(path: "/app/:id/charts", title: "App Charts", mode: .native, group: .charts),
        RouteDescriptor(path: "/sales", title: "Sales", mode: .native, group: .sales),
        RouteDescriptor(path: "/charts", title: "Charts", mode: .native, group: .charts),
        RouteDescriptor(path: "/calendar", title: "Calendar", mode: .native, group: .calendar),
        RouteDescriptor(path: "/pricechanges", title: "Price Changes", mode: .native, group: .sales),
        RouteDescriptor(path: "/upcoming", title: "Upcoming", mode: .native, group: .calendar),
        RouteDescriptor(path: "/freepackages", title: "Free Packages", mode: .native, group: .sales),
        RouteDescriptor(path: "/bundles", title: "Bundles", mode: .native, group: .sales),
        RouteDescriptor(path: "/top-rated", title: "Top Rated", mode: .native, group: .rankings),
        RouteDescriptor(path: "/topsellers/global", title: "Top Sellers (Global)", mode: .native, group: .rankings),
        RouteDescriptor(path: "/topsellers/weekly", title: "Top Sellers (Weekly)", mode: .native, group: .rankings),
        RouteDescriptor(path: "/mostfollowed", title: "Most Followed", mode: .native, group: .rankings),
        RouteDescriptor(path: "/mostwished", title: "Most Wished", mode: .native, group: .rankings),
        RouteDescriptor(path: "/wishlists", title: "Wishlists", mode: .native, group: .rankings),
        RouteDescriptor(path: "/dailyactiveusers", title: "Daily Active Users", mode: .native, group: .rankings),
        RouteDescriptor(path: "/calculator", title: "Calculator", mode: .webFallback, group: .utility),
        RouteDescriptor(path: "/tags", title: "Tags", mode: .webFallback, group: .utility),
        RouteDescriptor(path: "/patchnotes", title: "Patch Notes", mode: .webFallback, group: .utility),
        RouteDescriptor(path: "/events", title: "Events", mode: .webFallback, group: .utility, webURLOverride: "https://steamdb.info/sales/history/", fallbackWebURL: "https://store.steampowered.com/news/"),
        RouteDescriptor(path: "/year", title: "Year in Review", mode: .webFallback, group: .utility, webURLOverride: "https://steamdb.info/stats/releases/", fallbackWebURL: "https://store.steampowered.com/replay/"),
        RouteDescriptor(path: "/login", title: "Steam Login", mode: .webFallback, group: .utility, webURLOverride: "https://store.steampowered.com/login/"),
        RouteDescriptor(path: "/wishlist", title: "Steam Wishlist", mode: .webFallback, group: .utility, webURLOverride: "https://store.steampowered.com/wishlist/"),
        RouteDescriptor(path: "/news", title: "Steam News", mode: .webFallback, group: .utility, webURLOverride: "https://store.steampowered.com/news/"),
        RouteDescriptor(path: "/developer/:id", title: "Developer", mode: .webFallback, group: .entities),
        RouteDescriptor(path: "/publisher/:id", title: "Publisher", mode: .webFallback, group: .entities),
        RouteDescriptor(path: "/sub/:id", title: "Package", mode: .webFallback, group: .entities),
        RouteDescriptor(path: "/bundle/:id", title: "Bundle", mode: .webFallback, group: .entities),
        RouteDescriptor(path: "/depot/:id", title: "Depot", mode: .webFallback, group: .entities),
    ]
}
