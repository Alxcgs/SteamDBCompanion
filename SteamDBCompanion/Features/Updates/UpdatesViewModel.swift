import Foundation
import Combine

public enum SteamNewsSource: String, Hashable {
    case global
    case wishlist
}

public struct SteamNewsItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let url: URL
    public let publishedAt: Date?
    public let source: SteamNewsSource
    public let appID: Int?
}

@MainActor
public final class UpdatesViewModel: ObservableObject {
    @Published public var trackedApps: [SteamApp] = []
    @Published public var steamNews: [SteamNewsItem] = []
    @Published public var wishlistNews: [SteamNewsItem] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let dataSource: SteamDBDataSource
    private let wishlistManager: WishlistManager
    private let alertEngine: InAppAlertEngine

    public init(
        dataSource: SteamDBDataSource,
        wishlistManager: WishlistManager,
        alertEngine: InAppAlertEngine
    ) {
        self.dataSource = dataSource
        self.wishlistManager = wishlistManager
        self.alertEngine = alertEngine
    }

    public func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let wishlistedIDs = wishlistManager.wishlist.sorted()
        async let globalNewsTask: [SteamNewsItem] = fetchGlobalSteamNews()
        async let wishlistNewsTask: [SteamNewsItem] = fetchWishlistNews(appIDs: wishlistedIDs)

        do {
            var apps: [SteamApp] = []
            for appID in wishlistedIDs {
                let app = try await dataSource.fetchAppDetails(appID: appID)
                apps.append(app)
            }

            trackedApps = apps
            alertEngine.refresh(apps: apps)
        } catch {
            errorMessage = "\(L10n.tr("updates.error_refresh", fallback: "Failed to refresh updates")): \(error.localizedDescription)"
        }

        wishlistNews = await wishlistNewsTask
        steamNews = await globalNewsTask
    }

    private func fetchGlobalSteamNews() async -> [SteamNewsItem] {
        guard let feedURL = URL(string: "https://store.steampowered.com/feeds/news.xml") else {
            return []
        }

        do {
            var request = URLRequest(url: feedURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 20)
            request.setValue("application/rss+xml, text/xml;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("SteamDBCompanion-iOS", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            guard let xml = String(data: data, encoding: .utf8) else {
                return []
            }
            let parsed = parseNewsFeed(xml: xml, source: .global, appID: nil)
            if !parsed.isEmpty {
                return parsed
            }
            return parseNewsFeed(xml: String(decoding: data, as: UTF8.self), source: .global, appID: nil)
        } catch {
            return []
        }
    }

    private func fetchWishlistNews(appIDs: [Int]) async -> [SteamNewsItem] {
        let ids = Array(appIDs.prefix(12))
        guard !ids.isEmpty else { return [] }

        var merged: [SteamNewsItem] = []

        await withTaskGroup(of: [SteamNewsItem].self) { group in
            for appID in ids {
                group.addTask {
                    await self.fetchNewsForApp(appID: appID)
                }
            }

            for await items in group {
                merged.append(contentsOf: items)
            }
        }

        var deduped: [SteamNewsItem] = []
        var seen = Set<String>()
        for item in merged.sorted(by: { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }) {
            if seen.insert(item.id).inserted {
                deduped.append(item)
            }
            if deduped.count >= 40 {
                break
            }
        }
        return deduped
    }

    private func fetchNewsForApp(appID: Int) async -> [SteamNewsItem] {
        var components = URLComponents(string: "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/")
        components?.queryItems = [
            URLQueryItem(name: "appid", value: "\(appID)"),
            URLQueryItem(name: "count", value: "5"),
            URLQueryItem(name: "maxlength", value: "280"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else { return [] }

        do {
            var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 15)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("SteamDBCompanion-iOS", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            let payload = try JSONDecoder().decode(SteamNewsResponse.self, from: data)
            return payload.appnews.newsitems.compactMap { entry in
                guard let url = URL(string: entry.url) else { return nil }
                return SteamNewsItem(
                    id: entry.gid.isEmpty ? entry.url : entry.gid,
                    title: entry.title,
                    url: url,
                    publishedAt: Date(timeIntervalSince1970: TimeInterval(entry.date)),
                    source: .wishlist,
                    appID: appID
                )
            }
        } catch {
            return []
        }
    }

    private func parseNewsFeed(xml: String, source: SteamNewsSource, appID: Int?) -> [SteamNewsItem] {
        guard let itemRegex = try? NSRegularExpression(pattern: #"<item[^>]*>([\s\S]*?)</item>"#, options: [.caseInsensitive]) else {
            return []
        }

        let ns = xml as NSString
        let matches = itemRegex.matches(in: xml, options: [], range: NSRange(location: 0, length: ns.length))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        var items: [SteamNewsItem] = []
        for match in matches.prefix(20) {
            guard match.numberOfRanges > 1 else { continue }
            let itemXML = ns.substring(with: match.range(at: 1))

            guard
                let titleRaw = firstCapture(in: itemXML, pattern: #"<title>\s*(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?\s*</title>"#),
                let linkRaw = firstCapture(in: itemXML, pattern: #"<link>\s*(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?\s*</link>"#)
            else {
                continue
            }

            let cleanTitle = decodeHTML(titleRaw).trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanLink = decodeHTML(linkRaw).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: cleanLink), !cleanTitle.isEmpty else { continue }

            let pubDateRaw = firstCapture(in: itemXML, pattern: #"<pubDate>\s*([^<]+)\s*</pubDate>"#)
            let publishedAt = pubDateRaw.flatMap {
                formatter.date(from: $0.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            items.append(
                SteamNewsItem(
                    id: cleanLink,
                    title: cleanTitle,
                    url: url,
                    publishedAt: publishedAt,
                    source: source,
                    appID: appID
                )
            )
        }

        return items
    }

    private func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 else {
            return nil
        }
        return ns.substring(with: match.range(at: 1))
    }

    private func decodeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}

private struct SteamNewsResponse: Decodable {
    let appnews: SteamAppNews
}

private struct SteamAppNews: Decodable {
    let newsitems: [SteamAppNewsItem]
}

private struct SteamAppNewsItem: Decodable {
    let gid: String
    let title: String
    let url: String
    let date: Int
}
