import Foundation

public enum GatewayClientError: Error {
    case invalidBaseURL
    case invalidResponse
    case serverError(Int)
    case decodingFailed
}

public actor HTTPSteamDBGatewayClient: SteamDBGatewayClient {
    private struct RoutesPayload: Codable {
        let routes: [RouteDescriptor]
    }

    private let baseURL: URL
    private let isConfigured: Bool
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        if let baseURL {
            self.baseURL = baseURL
            self.isConfigured = true
        } else if let configured = ProcessInfo.processInfo.environment["STEAMDB_GATEWAY_URL"], let configuredURL = URL(string: configured) {
            self.baseURL = configuredURL
            self.isConfigured = true
        } else if let saved = UserDefaults.standard.string(forKey: "SteamDBGatewayURL"), let savedURL = URL(string: saved) {
            self.baseURL = savedURL
            self.isConfigured = true
        } else {
            self.baseURL = URL(string: "https://invalid.local")!
            self.isConfigured = false
        }

        self.session = session

        let configuredDecoder = JSONDecoder()
        configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
        configuredDecoder.dateDecodingStrategy = .iso8601
        self.decoder = configuredDecoder

        let configuredEncoder = JSONEncoder()
        configuredEncoder.keyEncodingStrategy = .convertToSnakeCase
        configuredEncoder.dateEncodingStrategy = .iso8601
        self.encoder = configuredEncoder
    }

    public func fetchNavigationRoutes() async throws -> [RouteDescriptor] {
        let payload: RoutesPayload = try await request(path: "/v1/navigation/routes")
        return payload.routes
    }

    public func fetchHome() async throws -> HomePayload {
        try await request(path: "/v1/home", queryItems: localeQueryItems())
    }

    public func search(query: String, page: Int) async throws -> SearchPayload {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        items.append(contentsOf: localeQueryItems())
        return try await request(
            path: "/v1/search",
            queryItems: items
        )
    }

    public func fetchAppOverview(appID: Int) async throws -> AppOverviewPayload {
        try await request(path: "/v1/apps/\(appID)/overview", queryItems: localeQueryItems())
    }

    public func fetchAppCharts(appID: Int, range: ChartRange) async throws -> AppChartsPayload {
        try await request(
            path: "/v1/apps/\(appID)/charts",
            queryItems: [URLQueryItem(name: "range", value: range.rawValue)]
        )
    }

    public func fetchCollection(kind: CollectionKind) async throws -> CollectionPayload {
        try await request(path: "/v1/collections/\(kind.rawValue)", queryItems: localeQueryItems())
    }

    public func fetchWatchlist(installationID: String) async throws -> WatchlistPayload {
        try await request(path: "/v1/watchlist/\(installationID)")
    }

    public func updateWatchlist(_ payload: WatchlistPayload) async throws -> WatchlistPayload {
        let body = try encoder.encode(payload)
        return try await request(path: "/v1/watchlist/\(payload.installationID)", method: "PUT", body: body)
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> T {
        guard isConfigured else {
            throw GatewayClientError.invalidBaseURL
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw GatewayClientError.invalidBaseURL
        }

        let joinedPath: String
        if path.hasPrefix("/") {
            joinedPath = baseURL.path + path
        } else {
            joinedPath = baseURL.path + "/" + path
        }
        components.path = joinedPath.replacingOccurrences(of: "//", with: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw GatewayClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SteamDBCompanion-iOS", forHTTPHeaderField: "User-Agent")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GatewayClientError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GatewayClientError.decodingFailed
        }
    }

    private func localeQueryItems() -> [URLQueryItem] {
        let country = storeCountryCode()
        let language = storeLanguageCode()
        return [
            URLQueryItem(name: "cc", value: country),
            URLQueryItem(name: "l", value: language)
        ]
    }

    private func storeCountryCode() -> String {
        let saved = UserDefaults.standard.string(forKey: "steamStoreCountryCode")?.lowercased() ?? "auto"
        if saved != "auto", saved.count == 2 {
            return saved
        }
        let localeCode = Locale.current.region?.identifier.lowercased() ?? "us"
        return localeCode.count == 2 ? localeCode : "us"
    }

    private func storeLanguageCode() -> String {
        if let appLanguage = UserDefaults.standard.string(forKey: "appLanguageMode"),
           appLanguage.count == 2 {
            return appLanguage.lowercased()
        }
        let saved = UserDefaults.standard.string(forKey: "steamStoreLanguageCode")?.lowercased() ?? "en"
        if saved.count == 2 {
            return saved
        }
        let localeLanguage = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        return localeLanguage.count == 2 ? localeLanguage : "en"
    }
}
