import Foundation

/// Represents a player count data point
public struct PlayerCountPoint: Identifiable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let playerCount: Int
    
    public init(id: UUID = UUID(), date: Date, playerCount: Int) {
        self.id = id
        self.date = date
        self.playerCount = playerCount
    }
}

/// Player count trend data
public struct PlayerTrend: Codable, Hashable {
    public let appID: Int
    public let points: [PlayerCountPoint]
    
    public var peakPlayers: PlayerCountPoint? {
        points.max(by: { $0.playerCount < $1.playerCount })
    }
    
    public var averagePlayers: Int {
        guard !points.isEmpty else { return 0 }
        let total = points.reduce(0) { $0 + $1.playerCount }
        return total / points.count
    }
    
    public init(appID: Int, points: [PlayerCountPoint]) {
        self.appID = appID
        self.points = points
    }
}
