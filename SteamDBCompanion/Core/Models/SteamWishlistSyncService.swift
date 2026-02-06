import Foundation
import WebKit

public enum SteamWishlistSyncError: LocalizedError {
    case notLoggedIn
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Sign in with Steam first, then run sync."
        case .invalidResponse:
            return "Steam did not return wishlist data."
        }
    }
}

@MainActor
public final class SteamWishlistSyncService {
    public static let shared = SteamWishlistSyncService()

    private init() {}

    public func syncWishlist(into wishlistManager: WishlistManager) async throws -> Int {
        let cookies = await loadSteamCookies()
        guard isLoggedIn(cookies: cookies) else {
            throw SteamWishlistSyncError.notLoggedIn
        }

        let payload = try await fetchWishlistPayload(cookies: cookies)
        let wishlistIDs = payload.rgWishlist ?? []
        wishlistManager.setWishlist(Set(wishlistIDs))
        applyCountryPreferenceIfAvailable(payload.countryCode)
        return wishlistIDs.count
    }

    private func loadSteamCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }

    private func isLoggedIn(cookies: [HTTPCookie]) -> Bool {
        cookies.contains { cookie in
            cookie.name == "steamLoginSecure" && cookie.domain.contains("steam")
        }
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

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw SteamWishlistSyncError.invalidResponse
        }

        let payload = try JSONDecoder().decode(SteamUserDataPayload.self, from: data)
        return SteamUserDataPayload(
            rgWishlist: Array(Set(payload.rgWishlist ?? [])).sorted(),
            countryCode: payload.countryCode?.lowercased()
        )
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
