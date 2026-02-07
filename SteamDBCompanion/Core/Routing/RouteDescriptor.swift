import Foundation

public enum RouteMode: String, Codable, Hashable {
    case native
    case webFallback
}

public enum RouteGroup: String, Codable, Hashable {
    case home
    case search
    case app
    case charts
    case sales
    case calendar
    case rankings
    case utility
    case entities
    case unknown
}

public struct RouteDescriptor: Identifiable, Codable, Hashable {
    public var id: String { path }
    public let path: String
    public let title: String
    public let mode: RouteMode
    public let group: RouteGroup
    public let enabled: Bool
    public let webURLOverride: String?
    public let fallbackWebURL: String?

    public init(
        path: String,
        title: String,
        mode: RouteMode,
        group: RouteGroup,
        enabled: Bool = true,
        webURLOverride: String? = nil,
        fallbackWebURL: String? = nil
    ) {
        self.path = path
        self.title = title
        self.mode = mode
        self.group = group
        self.enabled = enabled
        self.webURLOverride = webURLOverride
        self.fallbackWebURL = fallbackWebURL
    }
}

public struct RouteResolution: Hashable {
    public let descriptor: RouteDescriptor
    public let normalizedPath: String

    public init(descriptor: RouteDescriptor, normalizedPath: String) {
        self.descriptor = descriptor
        self.normalizedPath = normalizedPath
    }
}

public protocol RouteResolver {
    func resolve(path: String) -> RouteResolution
    func resolve(url: URL) -> RouteResolution
}
