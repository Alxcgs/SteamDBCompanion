import Foundation

public final class RealSteamDBDataSource: SteamDBDataSource {
    private let cacheSchemaVersion = "v4"
    private let gateway: SteamDBGatewayClient
    private let repository: SteamDBRepository
    private let networking: NetworkingService
    private let parser: HTMLParser
    private let baseURL = URL(string: "https://steamdb.info")!
    private let storeFeaturedURL = URL(string: "https://store.steampowered.com/api/featuredcategories/?cc=us&l=en")!
    private let storeSearchBaseURL = URL(string: "https://store.steampowered.com/api/storesearch/")!
    private let storeAppDetailsBaseURL = URL(string: "https://store.steampowered.com/api/appdetails")!
    private let steamCurrentPlayersBaseURL = URL(string: "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/")!
    private let steamChartsBaseURL = URL(string: "https://steamcharts.com/app/")!
    
    public init(
        gateway: SteamDBGatewayClient = HTTPSteamDBGatewayClient(),
        repository: SteamDBRepository = SteamDBRepository(),
        networking: NetworkingService = NetworkingService(),
        parser: HTMLParser = HTMLParser()
    ) {
        self.gateway = gateway
        self.repository = repository
        self.networking = networking
        self.parser = parser
    }

    public func fetchNavigationRoutes() async -> [RouteDescriptor] {
        do {
            return try await gateway.fetchNavigationRoutes()
        } catch {
            return RouteRegistry.defaultDescriptors
        }
    }

    public func searchApps(query: String) async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "search_\(query)_1_\(cacheSchemaVersion)", expiration: 600) {
                try await self.gateway.search(query: query, page: 1)
            }
            return uniqueApps(result.value.results.map(\.asSteamApp))
        } catch {
            return uniqueApps(try await fallbackSearch(query: query))
        }
    }
    
    public func fetchAppDetails(appID: Int) async throws -> SteamApp {
        do {
            let result = try await repository.fetch(cacheKey: "app_details_\(appID)_\(cacheSchemaVersion)", expiration: 1800) {
                try await self.gateway.fetchAppOverview(appID: appID)
            }
            let app = result.value.app.asSteamApp
            return await enrichWithPlayerStatsIfNeeded(app)
        } catch {
            let app = try await fallbackAppDetails(appID: appID)
            return await enrichWithPlayerStatsIfNeeded(app)
        }
    }
    
    public func fetchTrending() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            return uniqueApps(result.value.trending.map(\.asSteamApp))
        } catch {
            return uniqueApps(await fallbackTrending())
        }
    }
    
    public func fetchTopSellers() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            return uniqueApps(result.value.topSellers.map(\.asSteamApp))
        } catch {
            return uniqueApps(await fallbackTopSellers())
        }
    }
    
    public func fetchMostPlayed() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            if !result.value.mostPlayed.isEmpty {
                return result.value.mostPlayed.map(\.asSteamApp)
            }
        } catch {
            // Ignore and try collection endpoint.
        }

        do {
            let result = try await repository.fetch(cacheKey: "collection_daily_active_users_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchCollection(kind: .dailyActiveUsers)
            }
            return uniqueApps(result.value.items.map(\.asSteamApp))
        } catch {
            let fallback = await fallbackTopSellers()
            if !fallback.isEmpty {
                return uniqueApps(fallback)
            }
            return uniqueApps(await fallbackTrending())
        }
    }
    
    public func fetchPriceHistory(appID: Int) async throws -> PriceHistory {
        do {
            let result = try await repository.fetch(cacheKey: "app_charts_\(appID)_month_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchAppCharts(appID: appID, range: .month)
            }
            if !result.value.priceHistory.isEmpty {
                return result.value.asPriceHistory
            }
        } catch {
            // Fall back below.
        }
        return await fallbackPriceHistory(appID: appID)
    }
    
    public func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend {
        do {
            let result = try await repository.fetch(cacheKey: "app_charts_\(appID)_day_\(cacheSchemaVersion)", expiration: 900) {
                try await self.gateway.fetchAppCharts(appID: appID, range: .day)
            }
            if !result.value.playerTrend.isEmpty {
                return result.value.asPlayerTrend
            }
        } catch {
            // Fall back below.
        }
        return await fallbackPlayerTrend(appID: appID)
    }

    private func fallbackSearch(query: String) async throws -> [SteamApp] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: storeSearchBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "l", value: "en"),
            URLQueryItem(name: "cc", value: "us")
        ]

        if let searchURL = components?.url {
            do {
                let payload = try await repository.fetch(cacheKey: "store_search_\(trimmed)_1_\(cacheSchemaVersion)", expiration: 300) {
                    try await self.networking.fetch(url: searchURL, type: StoreSearchPayload.self)
                }
                let searchResults = payload.value.items
                    .filter { $0.type.lowercased() == "app" }
                    .map(asSteamApp)
                if !searchResults.isEmpty {
                    return searchResults
                }
            } catch {
                // Fall back to legacy HTML parsing.
            }
        }

        let url = baseURL.appendingPathComponent("search/").appending(queryItems: [URLQueryItem(name: "q", value: trimmed)])
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return try parser.parseTrending(html: html)
    }

    private func fallbackAppDetails(appID: Int) async throws -> SteamApp {
        let cacheKey = "legacy_app_details_\(appID)_\(cacheSchemaVersion)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: SteamApp.self, expiration: 86_400) {
            return cached
        }

        var components = URLComponents(url: storeAppDetailsBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "appids", value: "\(appID)"),
            URLQueryItem(name: "l", value: "en"),
            URLQueryItem(name: "cc", value: "us")
        ]

        if let detailsURL = components?.url {
            do {
                let response = try await repository.fetch(cacheKey: "store_app_details_\(appID)_\(cacheSchemaVersion)", expiration: 1800) {
                    try await self.networking.fetch(url: detailsURL, type: [String: StoreAppDetailsEntry].self)
                }

                if let entry = response.value["\(appID)"], entry.success, let data = entry.data {
                    let app = asSteamApp(data, appID: appID)
                    await CacheService.shared.save(app, for: cacheKey)
                    return app
                }
            } catch {
                // Fall through to SteamDB HTML parsing.
            }
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let app = try parser.parseAppDetails(html: html, appID: appID)
        await CacheService.shared.save(app, for: cacheKey)
        return app
    }

    private func fallbackPlayerTrend(appID: Int) async -> PlayerTrend {
        let cacheKey = "legacy_player_trend_\(appID)_\(cacheSchemaVersion)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: PlayerTrend.self, expiration: 86_400), !cached.points.isEmpty {
            return cached
        }

        let points = await fetchSteamChartsMonthlyPeaks(appID: appID)
        if !points.isEmpty {
            let trend = PlayerTrend(appID: appID, points: points)
            await CacheService.shared.save(trend, for: cacheKey)
            return trend
        }

        if let stale = await CacheService.shared.loadAllowExpired(key: cacheKey, type: PlayerTrend.self, expiration: 86_400) {
            return stale.value
        }

        return PlayerTrend(appID: appID, points: [])
    }

    private func fallbackPriceHistory(appID: Int) async -> PriceHistory {
        let cacheKey = "legacy_price_history_\(appID)_\(cacheSchemaVersion)"
        let cached = await CacheService.shared.load(key: cacheKey, type: PriceHistory.self, expiration: .greatestFiniteMagnitude)
        var points = cached?.points ?? []
        var currency = cached?.currency ?? "USD"

        var latestPrice: PriceInfo?
        if let app = try? await fetchAppDetails(appID: appID), let price = app.price {
            latestPrice = price
        } else if let price = await fetchStorePriceSnapshot(appID: appID) {
            latestPrice = price
        }

        if let price = latestPrice {
            currency = price.currency
            let now = Date()
            let shouldAppend = points.last.map { abs($0.price - price.current) > 0.0001 || now.timeIntervalSince($0.date) > 6 * 3600 } ?? true
            if shouldAppend {
                points.append(PriceHistoryPoint(date: now, price: price.current, discount: price.discountPercent))
            }

            if points.count == 1 {
                let seedDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
                let baselinePrice = price.initial > 0 ? price.initial : price.current
                points.insert(PriceHistoryPoint(date: seedDate, price: baselinePrice, discount: 0), at: 0)
            }
        }

        if points.count > 180 {
            points = Array(points.suffix(180))
        }

        let history = PriceHistory(appID: appID, currency: currency, points: points)
        await CacheService.shared.save(history, for: cacheKey)
        return history
    }

    private func fallbackTrending() async -> [SteamApp] {
        let cacheKey = "legacy_trending_\(cacheSchemaVersion)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return cached
        }

        do {
            let data = try await networking.fetchData(url: baseURL)
            let html = String(data: data, encoding: .utf8) ?? ""
            let apps = try parser.parseTrending(html: html)
            if !apps.isEmpty {
                await CacheService.shared.save(apps, for: cacheKey)
                return apps
            }
        } catch {
            // Continue to stale/store fallbacks.
        }

        if let stale = await CacheService.shared.loadAllowExpired(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return stale.value
        }

        let storeFallback = await fetchStoreTrending()
        if !storeFallback.isEmpty {
            await CacheService.shared.save(storeFallback, for: cacheKey)
        }
        return storeFallback
    }

    private func fallbackTopSellers() async -> [SteamApp] {
        let cacheKey = "legacy_top_sellers_\(cacheSchemaVersion)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return cached
        }

        let storeFallback = await fetchStoreTopSellers()
        if !storeFallback.isEmpty {
            await CacheService.shared.save(storeFallback, for: cacheKey)
            return storeFallback
        }

        if let stale = await CacheService.shared.loadAllowExpired(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return stale.value
        }

        return await fallbackTrending()
    }

    private func fetchStoreTrending() async -> [SteamApp] {
        do {
            let payload = try await repository.fetch(cacheKey: "steam_store_featured_\(cacheSchemaVersion)", expiration: 900) {
                try await self.networking.fetch(url: self.storeFeaturedURL, type: StoreFeaturedCategoriesPayload.self)
            }

            let specials = payload.value.specials.items.map(asSteamApp)
            if !specials.isEmpty {
                return specials
            }

            return payload.value.newReleases.items.map(asSteamApp)
        } catch {
            return []
        }
    }

    private func fetchStoreTopSellers() async -> [SteamApp] {
        do {
            let payload = try await repository.fetch(cacheKey: "steam_store_featured_\(cacheSchemaVersion)", expiration: 900) {
                try await self.networking.fetch(url: self.storeFeaturedURL, type: StoreFeaturedCategoriesPayload.self)
            }
            return payload.value.topSellers.items.map(asSteamApp)
        } catch {
            return []
        }
    }

    private func asSteamApp(_ item: StoreFeaturedItem) -> SteamApp {
        var platforms: [Platform] = []
        if item.windowsAvailable == true { platforms.append(.windows) }
        if item.macAvailable == true { platforms.append(.mac) }
        if item.linuxAvailable == true { platforms.append(.linux) }
        if platforms.isEmpty { platforms = [.windows] }

        let price: PriceInfo?
        if let finalPrice = item.finalPrice, finalPrice > 0 {
            let initialPrice = item.originalPrice ?? finalPrice
            price = PriceInfo(
                current: Double(finalPrice) / 100.0,
                currency: "USD",
                discountPercent: item.discountPercent ?? 0,
                initial: Double(initialPrice) / 100.0
            )
        } else {
            price = nil
        }

        return SteamApp(
            id: item.id,
            name: item.name,
            type: .game,
            price: price,
            headerImageURL: URL(string: item.smallCapsuleImage ?? item.headerImage ?? ""),
            platforms: platforms
        )
    }

    private func asSteamApp(_ item: StoreSearchItem) -> SteamApp {
        var platforms: [Platform] = []
        if item.platforms.windows == true { platforms.append(.windows) }
        if item.platforms.mac == true { platforms.append(.mac) }
        if item.platforms.linux == true { platforms.append(.linux) }
        if platforms.isEmpty { platforms = [.windows] }

        let price: PriceInfo?
        if let finalPrice = item.price?.finalPrice, finalPrice > 0 {
            let initialPrice = item.price?.initialPrice ?? finalPrice
            let currency = item.price?.currency ?? "USD"
            let discount = item.price?.discountPercent ?? max(0, Int((1.0 - (Double(finalPrice) / Double(max(initialPrice, 1)))) * 100.0))
            price = PriceInfo(
                current: Double(finalPrice) / 100.0,
                currency: currency,
                discountPercent: discount,
                initial: Double(initialPrice) / 100.0
            )
        } else {
            price = nil
        }

        return SteamApp(
            id: item.id,
            name: item.name,
            type: mapAppType(item.type),
            price: price,
            headerImageURL: URL(string: item.tinyImage ?? ""),
            platforms: platforms
        )
    }

    private func asSteamApp(_ data: StoreAppDetailsData, appID: Int) -> SteamApp {
        var platforms: [Platform] = []
        if data.platforms?.windows == true { platforms.append(.windows) }
        if data.platforms?.mac == true { platforms.append(.mac) }
        if data.platforms?.linux == true { platforms.append(.linux) }
        if platforms.isEmpty { platforms = [.windows] }

        let price: PriceInfo?
        if data.isFree == true {
            price = nil
        } else if let finalPrice = data.priceOverview?.finalPrice, finalPrice > 0 {
            let initialPrice = data.priceOverview?.initialPrice ?? finalPrice
            let currency = data.priceOverview?.currency ?? "USD"
            let discount = data.priceOverview?.discountPercent ?? max(0, Int((1.0 - (Double(finalPrice) / Double(max(initialPrice, 1)))) * 100.0))
            price = PriceInfo(
                current: Double(finalPrice) / 100.0,
                currency: currency,
                discountPercent: discount,
                initial: Double(initialPrice) / 100.0
            )
        } else {
            price = nil
        }

        return SteamApp(
            id: appID,
            name: data.name,
            type: mapAppType(data.type),
            price: price,
            headerImageURL: URL(string: data.headerImage ?? ""),
            shortDescription: data.shortDescription,
            platforms: platforms,
            developer: data.developers?.first,
            publisher: data.publishers?.first
        )
    }

    private func enrichWithPlayerStatsIfNeeded(_ app: SteamApp) async -> SteamApp {
        if let stats = app.playerStats, stats.currentPlayers > 0, stats.peak24h > 0, stats.allTimePeak > 0 {
            return app
        }

        let charts = await fetchSteamChartsStats(appID: app.id)
        let currentPlayers = await fetchCurrentPlayers(appID: app.id) ?? charts.current ?? app.playerStats?.currentPlayers
        let peak24h = charts.peak24h ?? app.playerStats?.peak24h ?? currentPlayers
        let allTimePeak = charts.allTime ?? app.playerStats?.allTimePeak ?? peak24h

        let stats: PlayerStats?
        if let currentPlayers, let peak24h, let allTimePeak, max(currentPlayers, max(peak24h, allTimePeak)) > 0 {
            stats = PlayerStats(currentPlayers: currentPlayers, peak24h: peak24h, allTimePeak: allTimePeak)
        } else {
            stats = app.playerStats
        }

        return SteamApp(
            id: app.id,
            name: app.name,
            type: app.type,
            price: app.price,
            headerImageURL: app.headerImageURL,
            shortDescription: app.shortDescription,
            platforms: app.platforms,
            developer: app.developer,
            publisher: app.publisher,
            releaseDate: app.releaseDate,
            playerStats: stats
        )
    }

    private func fetchCurrentPlayers(appID: Int) async -> Int? {
        var components = URLComponents(url: steamCurrentPlayersBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "appid", value: "\(appID)")]
        guard let url = components?.url else { return nil }

        do {
            let payload = try await repository.fetch(cacheKey: "steam_current_players_\(appID)_\(cacheSchemaVersion)", expiration: 120) {
                try await self.networking.fetch(url: url, type: SteamCurrentPlayersPayload.self)
            }
            guard payload.value.response.result == nil || payload.value.response.result == 1 else { return nil }
            return payload.value.response.playerCount
        } catch {
            return nil
        }
    }

    private func fetchSteamChartsStats(appID: Int) async -> (current: Int?, peak24h: Int?, allTime: Int?) {
        guard let url = URL(string: "\(steamChartsBaseURL.absoluteString)\(appID)") else {
            return (nil, nil, nil)
        }

        do {
            let data = try await repository.fetch(cacheKey: "steamcharts_page_\(appID)_\(cacheSchemaVersion)", expiration: 900) {
                try await self.networking.fetchData(url: url)
            }
            guard let html = String(data: data.value, encoding: .utf8) else {
                return (nil, nil, nil)
            }

            let current = matchNumber(in: html, pattern: #"<span class="num">([0-9,]+)</span>\s*<br>\s*players right now"#)
            let peak24h = matchNumber(in: html, pattern: #"<span class="num">([0-9,]+)</span>\s*<br>\s*24-hour peak"#)
            let allTime = matchNumber(in: html, pattern: #"<span class="num">([0-9,]+)</span>\s*<br>\s*all-time peak"#)
            return (current, peak24h, allTime)
        } catch {
            return (nil, nil, nil)
        }
    }

    private func fetchSteamChartsMonthlyPeaks(appID: Int) async -> [PlayerCountPoint] {
        guard let url = URL(string: "\(steamChartsBaseURL.absoluteString)\(appID)") else {
            return []
        }

        do {
            let data = try await repository.fetch(cacheKey: "steamcharts_page_\(appID)_\(cacheSchemaVersion)", expiration: 900) {
                try await self.networking.fetchData(url: url)
            }
            guard let html = String(data: data.value, encoding: .utf8) else {
                return []
            }
            return parseMonthlyPeakRows(from: html)
        } catch {
            return []
        }
    }

    private func parseMonthlyPeakRows(from html: String) -> [PlayerCountPoint] {
        let pattern = #"<td class="month-cell left">\s*([^<]+)\s*</td>[\s\S]*?<td class="right num">([0-9,]+)</td>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let ns = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMMM yyyy"

        var points: [PlayerCountPoint] = []
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let monthText = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let peakText = ns.substring(with: match.range(at: 2))
            guard
                let date = formatter.date(from: monthText),
                let peak = Int(peakText.replacingOccurrences(of: ",", with: ""))
            else {
                continue
            }
            points.append(PlayerCountPoint(date: date, playerCount: peak))
        }

        return points.sorted(by: { $0.date < $1.date })
    }

    private func matchNumber(in html: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = html as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: html, options: [], range: range), match.numberOfRanges > 1 else {
            return nil
        }
        let raw = ns.substring(with: match.range(at: 1))
        return Int(raw.replacingOccurrences(of: ",", with: ""))
    }

    private func mapAppType(_ rawType: String?) -> AppType {
        guard let rawType else { return .unknown }
        switch rawType.lowercased() {
        case "game": return .game
        case "dlc": return .dlc
        case "application", "demo", "hardware", "video": return .application
        case "tool": return .tool
        case "music": return .music
        default: return .unknown
        }
    }

    private func uniqueApps(_ apps: [SteamApp]) -> [SteamApp] {
        var seenIDs = Set<Int>()
        return apps.filter { app in
            seenIDs.insert(app.id).inserted
        }
    }

    private func fetchStorePriceSnapshot(appID: Int) async -> PriceInfo? {
        var components = URLComponents(url: storeAppDetailsBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "appids", value: "\(appID)"),
            URLQueryItem(name: "l", value: "en"),
            URLQueryItem(name: "cc", value: "us")
        ]
        guard let detailsURL = components?.url else { return nil }

        do {
            let response = try await repository.fetch(cacheKey: "store_price_snapshot_\(appID)_\(cacheSchemaVersion)", expiration: 1800) {
                try await self.networking.fetch(url: detailsURL, type: [String: StoreAppDetailsEntry].self)
            }
            guard
                let entry = response.value["\(appID)"],
                entry.success,
                let data = entry.data,
                data.isFree != true,
                let finalPrice = data.priceOverview?.finalPrice,
                finalPrice > 0
            else {
                return nil
            }

            let initialPrice = data.priceOverview?.initialPrice ?? finalPrice
            let currency = data.priceOverview?.currency ?? "USD"
            let safeInitial = max(initialPrice, 1)
            let ratio = Double(finalPrice) / Double(safeInitial)
            let computedDiscount = max(0, Int((1.0 - ratio) * 100.0))
            let discount = data.priceOverview?.discountPercent ?? computedDiscount
            return PriceInfo(
                current: Double(finalPrice) / 100.0,
                currency: currency,
                discountPercent: discount,
                initial: Double(initialPrice) / 100.0
            )
        } catch {
            return nil
        }
    }
}

private struct StoreFeaturedCategoriesPayload: Codable {
    let specials: StoreFeaturedSection
    let topSellers: StoreFeaturedSection
    let newReleases: StoreFeaturedSection
}

private struct StoreFeaturedSection: Codable {
    let items: [StoreFeaturedItem]
}

private struct StoreFeaturedItem: Codable {
    let id: Int
    let name: String
    let discountPercent: Int?
    let originalPrice: Int?
    let finalPrice: Int?
    let smallCapsuleImage: String?
    let headerImage: String?
    let windowsAvailable: Bool?
    let macAvailable: Bool?
    let linuxAvailable: Bool?
}

private struct StoreSearchPayload: Codable {
    let total: Int?
    let items: [StoreSearchItem]
}

private struct StoreSearchItem: Codable {
    let type: String
    let name: String
    let id: Int
    let price: StoreSearchPrice?
    let tinyImage: String?
    let platforms: StoreSearchPlatforms
}

private struct StoreSearchPrice: Codable {
    let currency: String?
    let initialPrice: Int?
    let finalPrice: Int?
    let discountPercent: Int?

    enum CodingKeys: String, CodingKey {
        case currency
        case initialPrice = "initial"
        case finalPrice = "final"
        case discountPercent
    }
}

private struct StoreSearchPlatforms: Codable {
    let windows: Bool?
    let mac: Bool?
    let linux: Bool?
}

private struct StoreAppDetailsEntry: Codable {
    let success: Bool
    let data: StoreAppDetailsData?
}

private struct StoreAppDetailsData: Codable {
    let type: String?
    let name: String
    let isFree: Bool?
    let shortDescription: String?
    let headerImage: String?
    let priceOverview: StoreAppDetailsPrice?
    let platforms: StoreSearchPlatforms?
    let developers: [String]?
    let publishers: [String]?
}

private struct StoreAppDetailsPrice: Codable {
    let currency: String?
    let initialPrice: Int?
    let finalPrice: Int?
    let discountPercent: Int?

    enum CodingKeys: String, CodingKey {
        case currency
        case initialPrice = "initial"
        case finalPrice = "final"
        case discountPercent
    }
}

private struct SteamCurrentPlayersPayload: Codable {
    let response: SteamCurrentPlayersResponse
}

private struct SteamCurrentPlayersResponse: Codable {
    let playerCount: Int
    let result: Int?
}
