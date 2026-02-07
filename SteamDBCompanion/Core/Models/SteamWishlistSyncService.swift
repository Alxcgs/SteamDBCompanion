import Foundation
import WebKit

public struct SteamSessionStatus: Sendable {
    public let isAuthenticated: Bool
    public let countryCode: String?
    public let lastError: String?

    public init(isAuthenticated: Bool, countryCode: String? = nil, lastError: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.countryCode = countryCode
        self.lastError = lastError
    }
}

public struct SteamWishlistSyncResult: Sendable {
    public let appIDs: [Int]
    public let countryCode: String?
    public let isAuthenticated: Bool
    public let timestamp: Date

    public init(appIDs: [Int], countryCode: String?, isAuthenticated: Bool, timestamp: Date) {
        self.appIDs = appIDs
        self.countryCode = countryCode
        self.isAuthenticated = isAuthenticated
        self.timestamp = timestamp
    }
}

public enum SteamWishlistSyncError: LocalizedError, Equatable {
    case notLoggedIn
    case invalidResponse
    case rateLimited
    case networkFailure

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return L10n.tr("steam_sync.error_not_logged_in", fallback: "Sign in with Steam first, then run sync.")
        case .invalidResponse:
            return L10n.tr("steam_sync.error_invalid_response", fallback: "Steam did not return wishlist data.")
        case .rateLimited:
            return L10n.tr("steam_sync.error_rate_limited", fallback: "Steam temporarily rate-limited this request. Please retry in a moment.")
        case .networkFailure:
            return L10n.tr("steam_sync.error_network", fallback: "Network error while contacting Steam.")
        }
    }
}

@MainActor
public final class SteamWishlistSyncService {
    public static let shared = SteamWishlistSyncService()

    private init() {}

    public func checkSteamSession() async -> SteamSessionStatus {
        let cookies = await loadSteamCookies()
        guard hasSessionCookies(cookies: cookies) else {
            return SteamSessionStatus(isAuthenticated: false)
        }

        do {
            let payload = try await fetchWishlistPayload(cookies: cookies)
            return SteamSessionStatus(
                isAuthenticated: true,
                countryCode: payload.countryCode?.lowercased()
            )
        } catch {
            return SteamSessionStatus(
                isAuthenticated: false,
                lastError: error.localizedDescription
            )
        }
    }

    public func syncWishlist() async throws -> SteamWishlistSyncResult {
        let cookies = await loadSteamCookies()
        guard hasSessionCookies(cookies: cookies) else {
            throw SteamWishlistSyncError.notLoggedIn
        }

        let payload = try await fetchWishlistPayload(cookies: cookies)
        let normalizedIDs = Array(Set(payload.rgWishlist ?? [])).sorted()
        return SteamWishlistSyncResult(
            appIDs: normalizedIDs,
            countryCode: payload.countryCode?.lowercased(),
            isAuthenticated: true,
            timestamp: Date()
        )
    }

    public func syncWishlist(into wishlistManager: WishlistManager) async throws -> SteamWishlistSyncResult {
        let result = try await syncWishlist()
        wishlistManager.applySyncSuccess(appIDs: Set(result.appIDs), syncedAt: result.timestamp)
        applyCountryPreferenceIfAvailable(result.countryCode)
        return result
    }

    private func loadSteamCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }

    private func hasSessionCookies(cookies: [HTTPCookie]) -> Bool {
        let steamCookies = cookies.filter { $0.domain.contains("steam") }
        let names = Set(steamCookies.map(\.name))
        return names.contains("steamLoginSecure") && names.contains("sessionid")
    }

    private func fetchWishlistPayload(cookies: [HTTPCookie]) async throws -> SteamUserDataPayload {
        guard let url = URL(string: "https://store.steampowered.com/dynamicstore/userdata/") else {
            throw SteamWishlistSyncError.invalidResponse
        }

        let config = URLSessionConfiguration.ephemeral
        let cookieStorage = HTTPCookieStorage()
        config.httpCookieStorage = cookieStorage
        config.httpShouldSetCookies = true
        for cookie in cookies where cookie.domain.contains("steam") {
            cookieStorage.setCookie(cookie)
        }

        let session = URLSession(configuration: config)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SteamDBCompanion-iOS", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SteamWishlistSyncError.invalidResponse
            }

            if httpResponse.statusCode == 429 {
                throw SteamWishlistSyncError.rateLimited
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw SteamWishlistSyncError.invalidResponse
            }

            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
            if contentType.contains("text/html") || (httpResponse.url?.path.lowercased().contains("/login") == true) {
                throw SteamWishlistSyncError.notLoggedIn
            }

            guard let payload = try? JSONDecoder().decode(SteamUserDataPayload.self, from: data) else {
                if let text = String(data: data, encoding: .utf8)?.lowercased(),
                   text.contains("sign in") || text.contains("steamcommunity") || text.contains("login") {
                    throw SteamWishlistSyncError.notLoggedIn
                }
                throw SteamWishlistSyncError.invalidResponse
            }
            return SteamUserDataPayload(
                rgWishlist: Array(Set(payload.rgWishlist ?? [])).sorted(),
                countryCode: payload.countryCode?.lowercased()
            )
        } catch let error as SteamWishlistSyncError {
            throw error
        } catch let error as URLError {
            if error.code == .timedOut || error.code == .cannotFindHost || error.code == .cannotConnectToHost || error.code == .networkConnectionLost || error.code == .notConnectedToInternet {
                throw SteamWishlistSyncError.networkFailure
            }
            throw SteamWishlistSyncError.networkFailure
        } catch {
            throw SteamWishlistSyncError.invalidResponse
        }
    }

    private func applyCountryPreferenceIfAvailable(_ countryCode: String?) {
        guard
            let countryCode,
            countryCode.count == 2
        else {
            return
        }
        UserDefaults.standard.set(countryCode, forKey: "steamStoreCountryCode")
    }
}

private struct SteamUserDataPayload: Decodable {
    let rgWishlist: [Int]?
    let countryCode: String?

    enum CodingKeys: String, CodingKey {
        case rgWishlist
        case countryCode = "country_code"
    }
}
