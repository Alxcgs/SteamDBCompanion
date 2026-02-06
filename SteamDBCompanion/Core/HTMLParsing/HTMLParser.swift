import Foundation

public enum HTMLParsingError: Error {
    case invalidHTML
    case elementNotFound(String)
    case parsingFailed(Error)
}

public final class HTMLParser {
    
    public init() {}
    
    public func parseTrending(html: String) throws -> [SteamApp] {
        let rowPattern = #"<tr[^>]*data-appid="(\d+)"[^>]*>([\s\S]*?)</tr>"#
        guard let regex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive]) else {
            return []
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        var apps: [SteamApp] = []
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let idText = nsHTML.substring(with: match.range(at: 1))
            let rowHTML = nsHTML.substring(with: match.range(at: 2))
            guard let id = Int(idText), id > 0 else { continue }

            let name = extractName(from: rowHTML) ?? "Unknown"
            let price = parsePrice(rowHTML)
            apps.append(SteamApp(id: id, name: name, type: .game, price: price))
        }

        if !apps.isEmpty {
            return apps
        }

        // Fallback: parse direct app links when table rows are not present.
        let linkPattern = #"href="/app/(\d+)/"[^>]*>([^<]+)</a>"#
        guard let linkRegex = try? NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive]) else {
            return []
        }
        let linkMatches = linkRegex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))
        for match in linkMatches {
            guard match.numberOfRanges >= 3 else { continue }
            let idText = nsHTML.substring(with: match.range(at: 1))
            let nameText = nsHTML.substring(with: match.range(at: 2))
            guard let id = Int(idText), id > 0 else { continue }
            let name = decodeHTML(nameText).trimmingCharacters(in: .whitespacesAndNewlines)
            apps.append(SteamApp(id: id, name: name, type: .game, price: nil))
        }
        return apps
    }
    
    public func parseAppDetails(html: String, appID: Int) throws -> SteamApp {
        let namePattern = #"<h1[^>]*itemprop="name"[^>]*>([\s\S]*?)</h1>"#
        let name = matchFirstCapture(in: html, pattern: namePattern) ?? "Unknown"
        let cleanedName = decodeHTML(stripTags(name)).trimmingCharacters(in: .whitespacesAndNewlines)

        let playersPattern = #"<strong>\s*([0-9,]+)\s*</strong>"#
        let playersText = matchFirstCapture(in: html, pattern: playersPattern) ?? "0"
        let currentPlayers = Int(playersText.replacingOccurrences(of: ",", with: "")) ?? 0

        let pricePattern = #"<div[^>]*class="[^"]*price[^"]*"[^>]*>([\s\S]*?)</div>"#
        let priceText = matchFirstCapture(in: html, pattern: pricePattern) ?? ""
        let price = parsePrice(priceText)

        return SteamApp(
            id: appID,
            name: cleanedName,
            type: .game,
            price: price,
            platforms: inferPlatforms(from: html),
            developer: parseLabelValue(html, label: "Developer"),
            publisher: parseLabelValue(html, label: "Publisher"),
            playerStats: PlayerStats(currentPlayers: currentPlayers, peak24h: 0, allTimePeak: 0)
        )
    }
    
    private func parsePrice(_ text: String) -> PriceInfo? {
        let normalizedText = decodeHTML(stripTags(text)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty, normalizedText.lowercased() != "free" else { return nil }
        // Simple parser, assumes format like "$19.99"
        let digits = normalizedText.filter { "0123456789.".contains($0) }
        guard let value = Double(digits) else { return nil }
        
        return PriceInfo(
            current: value,
            currency: "USD", // Assumption
            discountPercent: 0,
            initial: value
        )
    }

    private func extractName(from rowHTML: String) -> String? {
        let pattern = #"href="/app/\d+/"[^>]*>([\s\S]*?)</a>"#
        guard let raw = matchFirstCapture(in: rowHTML, pattern: pattern) else { return nil }
        return decodeHTML(stripTags(raw)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripTags(_ value: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
            return value
        }
        let nsValue = value as NSString
        return regex.stringByReplacingMatches(
            in: value,
            options: [],
            range: NSRange(location: 0, length: nsValue.length),
            withTemplate: " "
        )
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

    private func matchFirstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        guard match.numberOfRanges > 1 else { return nil }
        return nsText.substring(with: match.range(at: 1))
    }

    private func inferPlatforms(from html: String) -> [Platform] {
        let lower = html.lowercased()
        var platforms: [Platform] = []
        if lower.contains("windows") { platforms.append(.windows) }
        if lower.contains("mac") { platforms.append(.mac) }
        if lower.contains("linux") { platforms.append(.linux) }
        if platforms.isEmpty { platforms = [.windows] }
        return platforms
    }

    private func parseLabelValue(_ html: String, label: String) -> String? {
        let escapedLabel = NSRegularExpression.escapedPattern(for: label)
        let pattern = "\(escapedLabel)[\\s\\S]{0,120}?<a[^>]*>([\\s\\S]*?)</a>"
        guard let raw = matchFirstCapture(in: html, pattern: pattern) else { return nil }
        let clean = decodeHTML(stripTags(raw)).trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }
}
