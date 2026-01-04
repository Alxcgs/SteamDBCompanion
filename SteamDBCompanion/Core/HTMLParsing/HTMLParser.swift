import Foundation
import SwiftSoup

public enum HTMLParsingError: Error {
    case invalidHTML
    case elementNotFound(String)
    case parsingFailed(Error)
}

public final class HTMLParser {
    
    public init() {}
    
    public func parseTrending(html: String) throws -> [SteamApp] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select(".table-products tbody tr")
            
            var apps: [SteamApp] = []
            
            for row in rows {
                let nameElement = try row.select("td:nth-child(3) a").first()
                let name = try nameElement?.text() ?? "Unknown"
                
                let idAttr = try row.attr("data-appid")
                let id = Int(idAttr) ?? 0
                
                // Price parsing (simplified)
                let priceText = try row.select("td:nth-child(4)").text()
                let price = parsePrice(priceText)
                
                let app = SteamApp(
                    id: id,
                    name: name,
                    type: .game,
                    price: price
                )
                apps.append(app)
            }
            
            return apps
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }
    
    public func parseAppDetails(html: String, appID: Int) throws -> SteamApp {
        do {
            let doc = try SwiftSoup.parse(html)
            
            let name = try doc.select("h1[itemprop=name]").text()
            let _ = try doc.select(".header-description").text()
            
            // Extract player counts
            let playersText = try doc.select(".app-chart-numbers strong").first()?.text() ?? "0"
            let currentPlayers = Int(playersText.replacingOccurrences(of: ",", with: "")) ?? 0
            
            // Extract price
            let priceText = try doc.select(".price-line .price").first()?.text() ?? ""
            let price = parsePrice(priceText)
            
            return SteamApp(
                id: appID,
                name: name,
                type: .game,
                price: price,
                platforms: [.windows], // Placeholder
                developer: "Unknown",
                publisher: "Unknown",
                playerStats: PlayerStats(currentPlayers: currentPlayers, peak24h: 0, allTimePeak: 0)
            )
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }

    public func parsePackages(html: String) throws -> [SteamPackage] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table.table-packages tbody tr, table.table-app-packages tbody tr")

            return try rows.map { row in
                let idText = try row.attr("data-packageid").isEmpty ? row.select("td:nth-child(1)").text() : row.attr("data-packageid")
                let id = Int(idText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                let name = try row.select("td:nth-child(2) a, td:nth-child(2)").text()
                let priceText = try row.select("td:nth-child(3)").text()
                let typeText = try row.select("td:nth-child(4)").text()

                return SteamPackage(
                    id: id,
                    name: name.isEmpty ? "Unknown Package" : name,
                    price: parsePrice(priceText),
                    type: typeText.isEmpty ? nil : typeText
                )
            }
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }

    public func parseDepots(html: String) throws -> [SteamDepot] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table.table-app-depots tbody tr, table.table-depots tbody tr")

            return try rows.map { row in
                let idText = try row.attr("data-depotid").isEmpty ? row.select("td:nth-child(1)").text() : row.attr("data-depotid")
                let id = Int(idText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                let name = try row.select("td:nth-child(2) a, td:nth-child(2)").text()
                let size = try row.select("td:nth-child(3)").text()
                let manifest = try row.select("td:nth-child(4)").text()

                return SteamDepot(
                    id: id,
                    name: name.isEmpty ? "Unknown Depot" : name,
                    size: size.isEmpty ? nil : size,
                    manifest: manifest.isEmpty ? nil : manifest
                )
            }
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }

    public func parseBadges(html: String) throws -> [SteamBadge] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table.table-app-badges tbody tr, table.table-badges tbody tr")

            return try rows.enumerated().map { index, row in
                let name = try row.select("td:nth-child(2) a, td:nth-child(2)").text()
                let level = try row.select("td:nth-child(3)").text()
                let rarity = try row.select("td:nth-child(4)").text()

                return SteamBadge(
                    id: index,
                    name: name.isEmpty ? "Unknown Badge" : name,
                    level: level.isEmpty ? nil : level,
                    rarity: rarity.isEmpty ? nil : rarity
                )
            }
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }

    public func parseChangelogs(html: String) throws -> [SteamChangelogEntry] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table.table-app-changelogs tbody tr, table.table-changelogs tbody tr")

            return try rows.enumerated().map { index, row in
                let date = try row.select("td:nth-child(1)").text()
                let build = try row.select("td:nth-child(2)").text()
                let summary = try row.select("td:nth-child(3)").text()

                return SteamChangelogEntry(
                    id: "changelog-\(index)",
                    buildID: build.isEmpty ? nil : build,
                    date: date.isEmpty ? nil : date,
                    summary: summary.isEmpty ? "No details available." : summary
                )
            }
        } catch {
            throw HTMLParsingError.parsingFailed(error)
        }
    }

    public func parsePriceHistory(html: String, appID: Int) throws -> PriceHistory {
        let points = try parseChartSeries(html: html, seriesNames: ["Price", "Price (USD)", "Price (USD$)"])
            .map { PriceHistoryPoint(date: $0.date, price: $0.value, discount: 0) }
        return PriceHistory(appID: appID, currency: "USD", points: points)
    }
    
    public func parsePlayerTrend(html: String, appID: Int) throws -> PlayerTrend {
        let points = try parseChartSeries(html: html, seriesNames: ["Players", "In-Game", "Players (24h)"])
            .map { PlayerCountPoint(date: $0.date, playerCount: Int($0.value)) }
        return PlayerTrend(appID: appID, points: points)
    }

    private struct ChartSeriesPoint {
        let date: Date
        let value: Double
    }

    private func parseChartSeries(html: String, seriesNames: [String]) throws -> [ChartSeriesPoint] {
        for seriesName in seriesNames {
            if let seriesRange = html.range(of: "name: '\(seriesName)'") ?? html.range(of: "name: \"\(seriesName)\"") {
                let tail = String(html[seriesRange.lowerBound...])
                guard let dataRange = tail.range(of: "data: [") else {
                    continue
                }

                let dataTail = String(tail[dataRange.upperBound...])
                guard let endRange = dataTail.range(of: "]", options: .backwards) else {
                    continue
                }

                let dataBody = String(dataTail[..<endRange.lowerBound])
                let regex = try NSRegularExpression(pattern: "\\[(\\d+),(\\d+(?:\\.\\d+)?)\\]")
                let matches = regex.matches(in: dataBody, range: NSRange(dataBody.startIndex..., in: dataBody))

                let points: [ChartSeriesPoint] = matches.compactMap { match in
                    guard let tsRange = Range(match.range(at: 1), in: dataBody),
                          let valueRange = Range(match.range(at: 2), in: dataBody) else {
                        return nil
                    }

                    let timestamp = Double(dataBody[tsRange]) ?? 0
                    let value = Double(dataBody[valueRange]) ?? 0
                    let date = Date(timeIntervalSince1970: timestamp / 1000)
                    return ChartSeriesPoint(date: date, value: value)
                }

                if !points.isEmpty {
                    return points
                }
            }
        }

        return []
    }
    
    private func parsePrice(_ text: String) -> PriceInfo? {
        guard !text.isEmpty, text != "Free" else { return nil }
        // Simple parser, assumes format like "$19.99"
        let digits = text.filter { "0123456789.".contains($0) }
        guard let value = Double(digits) else { return nil }
        
        return PriceInfo(
            current: value,
            currency: "USD", // Assumption
            discountPercent: 0,
            initial: value
        )
    }
}
