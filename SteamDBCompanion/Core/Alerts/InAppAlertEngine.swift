import Foundation
import Combine

public struct AppSnapshot: Identifiable, Codable, Hashable {
    public var id: Int { appID }
    public let appID: Int
    public let name: String
    public let price: Double?
    public let players: Int?
    public let updatedAt: Date

    public init(appID: Int, name: String, price: Double?, players: Int?, updatedAt: Date = Date()) {
        self.appID = appID
        self.name = name
        self.price = price
        self.players = players
        self.updatedAt = updatedAt
    }
}

public protocol AlertDiffService {
    func detectDiffs(previous: [AppSnapshot], current: [AppSnapshot]) -> [AlertDiff]
}

public struct DefaultAlertDiffService: AlertDiffService {
    private let playerThreshold: Double

    public init(playerThreshold: Double = 0.2) {
        self.playerThreshold = playerThreshold
    }

    public func detectDiffs(previous: [AppSnapshot], current: [AppSnapshot]) -> [AlertDiff] {
        let previousByID = Dictionary(uniqueKeysWithValues: previous.map { ($0.appID, $0) })
        var diffs: [AlertDiff] = []

        for snapshot in current {
            guard let old = previousByID[snapshot.appID] else { continue }

            if let oldPrice = old.price, let newPrice = snapshot.price, oldPrice != newPrice {
                let type: AlertDiff.AlertType = newPrice < oldPrice ? .priceDrop : .priceRise
                diffs.append(AlertDiff(appID: snapshot.appID, type: type, oldValue: oldPrice, newValue: newPrice))
            }

            if let oldPlayers = old.players, let newPlayers = snapshot.players, oldPlayers > 0 {
                let delta = abs(Double(newPlayers - oldPlayers)) / Double(oldPlayers)
                if delta >= playerThreshold {
                    let type: AlertDiff.AlertType = newPlayers > oldPlayers ? .playerSpike : .playerDrop
                    diffs.append(AlertDiff(appID: snapshot.appID, type: type, oldValue: Double(oldPlayers), newValue: Double(newPlayers)))
                }
            }
        }

        return diffs.sorted { $0.detectedAt > $1.detectedAt }
    }
}

@MainActor
public final class InAppAlertEngine: ObservableObject {
    @Published public private(set) var history: [AlertDiff] = []
    @Published public private(set) var latestDiffs: [AlertDiff] = []

    private let diffService: AlertDiffService
    private let storage: UserDefaults
    private let snapshotsKey = "in_app_snapshots"
    private let historyKey = "in_app_alert_history"

    public init(diffService: AlertDiffService = DefaultAlertDiffService(), storage: UserDefaults = .standard) {
        self.diffService = diffService
        self.storage = storage
        self.history = load([AlertDiff].self, for: historyKey) ?? []
    }

    public func refresh(apps: [SteamApp]) {
        let currentSnapshots = apps.map {
            AppSnapshot(appID: $0.id, name: $0.name, price: $0.price?.current, players: $0.playerStats?.currentPlayers)
        }
        let previousSnapshots = load([AppSnapshot].self, for: snapshotsKey) ?? []
        let newDiffs = diffService.detectDiffs(previous: previousSnapshots, current: currentSnapshots)

        latestDiffs = newDiffs

        if !newDiffs.isEmpty {
            history = Array((newDiffs + history).prefix(300))
            save(history, for: historyKey)
        }

        save(currentSnapshots, for: snapshotsKey)
    }

    public func clearHistory() {
        history = []
        latestDiffs = []
        storage.removeObject(forKey: historyKey)
    }

    private func save<T: Encodable>(_ value: T, for key: String) {
        if let data = try? JSONEncoder().encode(value) {
            storage.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = storage.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
