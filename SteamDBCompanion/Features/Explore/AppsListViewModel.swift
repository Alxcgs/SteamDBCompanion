import Foundation
import SwiftUI

@MainActor
public final class AppsListViewModel: ObservableObject {
    @Published public var apps: [SteamApp] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let dataSource: SteamDBDataSource
    private let mode: AppsListMode

    public init(mode: AppsListMode, dataSource: SteamDBDataSource) {
        self.mode = mode
        self.dataSource = dataSource
    }

    public func load() async {
        isLoading = true
        errorMessage = nil

        do {
            switch mode {
            case .trending:
                apps = try await dataSource.fetchTrending()
            case .topSellers:
                apps = try await dataSource.fetchTopSellers()
            case .mostPlayed:
                apps = try await dataSource.fetchMostPlayed()
            }
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public var title: String {
        mode.rawValue
    }
}

public enum AppsListMode: String {
    case trending = "Trending"
    case topSellers = "Top Sellers"
    case mostPlayed = "Most Played"
}
