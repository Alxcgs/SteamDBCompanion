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
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        if let baseURL {
            self.baseURL = baseURL
        } else if let configured = ProcessInfo.processInfo.environment["STEAMDB_GATEWAY_URL"], let configuredURL = URL(string: configured) {
            self.baseURL = configuredURL
        } else if let saved = UserDefaults.standard.string(forKey: "SteamDBGatewayURL"), let savedURL = URL(string: saved) {
            self.baseURL = savedURL
        } else {
            self.baseURL = URL(string: "http://127.0.0.1:8787")!
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
        try await request(path: "/v1/home")
    }

    public func search(query: String, page: Int) async throws -> SearchPayload {
        try await request(
            path: "/v1/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        )
    }

    public func fetchAppOverview(appID: Int) async throws -> AppOverviewPayload {
        try await request(path: "/v1/apps/\(appID)/overview")
    }

    public func fetchAppCharts(appID: Int, range: ChartRange) async throws -> AppChartsPayload {
        try await request(
            path: "/v1/apps/\(appID)/charts",
            queryItems: [URLQueryItem(name: "range", value: range.rawValue)]
        )
    }

    public func fetchCollection(kind: CollectionKind) async throws -> CollectionPayload {
        try await request(path: "/v1/collections/\(kind.rawValue)")
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
}
