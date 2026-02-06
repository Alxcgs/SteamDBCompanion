import XCTest
@testable import SteamDBCompanion

final class RepositoryTests: XCTestCase {
    private enum TestError: Error {
        case upstream
    }

    func testFetchReturnsRemoteAndCaches() async throws {
        let repository = SteamDBRepository()
        let key = "repo_remote_\(UUID().uuidString)"
        let payload = ["value": 42]

        let result = try await repository.fetch(cacheKey: key, expiration: 3600) {
            payload
        }

        XCTAssertEqual(result.freshness, .fresh)
        XCTAssertEqual(result.source, .remote)
        XCTAssertEqual(result.value["value"], 42)

        let cached = await CacheService.shared.load(key: key, type: [String: Int].self, expiration: 3600)
        XCTAssertEqual(cached?["value"], 42)
    }

    func testFetchReturnsStaleCacheWhenRemoteFails() async throws {
        let repository = SteamDBRepository()
        let key = "repo_stale_\(UUID().uuidString)"
        let cachedPayload = ["cached": 1]
        await CacheService.shared.save(cachedPayload, for: key)

        let result = try await repository.fetch(cacheKey: key, expiration: -1) {
            throw TestError.upstream
        }

        XCTAssertEqual(result.freshness, .stale)
        XCTAssertEqual(result.source, .cache)
        XCTAssertEqual(result.value["cached"], 1)
    }
}
