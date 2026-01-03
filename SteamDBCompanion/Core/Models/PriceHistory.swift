import Foundation

/// Represents a price point in history
public struct PriceHistoryPoint: Identifiable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let price: Double
    public let discount: Int // percentage
    
    public init(id: UUID = UUID(), date: Date, price: Double, discount: Int = 0) {
        self.id = id
        self.date = date
        self.price = price
        self.discount = discount
    }
}

/// Price history for an app
public struct PriceHistory: Codable, Hashable {
    public let appID: Int
    public let currency: String
    public let points: [PriceHistoryPoint]
    
    public var lowestPrice: PriceHistoryPoint? {
        points.min(by: { $0.price < $1.price })
    }
    
    public var highestPrice: PriceHistoryPoint? {
        points.max(by: { $0.price < $1.price })
    }
    
    public init(appID: Int, currency: String, points: [PriceHistoryPoint]) {
        self.appID = appID
        self.currency = currency
        self.points = points
    }
}
