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
