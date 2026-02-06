import Foundation

public enum RepositoryFreshness: String, Codable, Hashable {
    case fresh
    case stale
}

public enum RepositorySource: String, Codable, Hashable {
    case remote
    case cache
}

public struct RepositoryValue<T> {
    public let value: T
    public let freshness: RepositoryFreshness
    public let source: RepositorySource

    public init(value: T, freshness: RepositoryFreshness, source: RepositorySource) {
        self.value = value
        self.freshness = freshness
        self.source = source
    }
}

public enum RepositoryError: Error {
    case upstream(Error)
    case noData
}

public actor SteamDBRepository {
    private let cacheService: CacheService

    public init(cacheService: CacheService = .shared) {
        self.cacheService = cacheService
    }

    public func fetch<T: Codable>(
        cacheKey: String,
        expiration: TimeInterval,
        forceRefresh: Bool = false,
        loader: () async throws -> T
    ) async throws -> RepositoryValue<T> {
        if !forceRefresh, let cached = await cacheService.load(key: cacheKey, type: T.self, expiration: expiration) {
            return RepositoryValue(value: cached, freshness: .fresh, source: .cache)
        }

        do {
            let remoteValue = try await loader()
            await cacheService.save(remoteValue, for: cacheKey)
            return RepositoryValue(value: remoteValue, freshness: .fresh, source: .remote)
        } catch {
            if let stale = await cacheService.loadAllowExpired(key: cacheKey, type: T.self, expiration: expiration) {
                return RepositoryValue(value: stale.value, freshness: .stale, source: .cache)
            }
            throw RepositoryError.upstream(error)
        }
    }
}
