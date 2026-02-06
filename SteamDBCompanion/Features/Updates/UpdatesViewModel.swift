import Foundation
import Combine

public struct SteamNewsItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let url: URL
    public let publishedAt: Date?
}

@MainActor
public final class UpdatesViewModel: ObservableObject {
    @Published public var trackedApps: [SteamApp] = []
    @Published public var steamNews: [SteamNewsItem] = []
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

        async let newsTask: [SteamNewsItem] = fetchSteamNews()

        do {
            var apps: [SteamApp] = []
            for appID in wishlistManager.wishlist.sorted() {
                let app = try await dataSource.fetchAppDetails(appID: appID)
                apps.append(app)
            }

            trackedApps = apps
            alertEngine.refresh(apps: apps)
        } catch {
            errorMessage = "Failed to refresh updates: \(error.localizedDescription)"
        }

        steamNews = await newsTask
    }

    private func fetchSteamNews() async -> [SteamNewsItem] {
        guard let feedURL = URL(string: "https://store.steampowered.com/feeds/news.xml") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: feedURL)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            guard let xml = String(data: data, encoding: .utf8) else {
                return []
            }
            return parseNewsFeed(xml: xml)
        } catch {
            return []
        }
    }

    private func parseNewsFeed(xml: String) -> [SteamNewsItem] {
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
                    publishedAt: publishedAt
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
