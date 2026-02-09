import Foundation

public enum SteamWebAPIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingFailed
}

@MainActor
public final class SteamWebAPIClient {
    public static let shared = SteamWebAPIClient()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchWishlist(steamID: String) async throws -> [Int] {
        guard var components = URLComponents(string: "https://api.steampowered.com/IWishlistService/GetWishlist/v1/") else {
            throw SteamWebAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "steamid", value: steamID)
        ]
        guard let url = components.url else {
            throw SteamWebAPIError.invalidURL
        }

        var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SteamDBCompanion-iOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SteamWebAPIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SteamWebAPIError.serverError(http.statusCode)
        }

        do {
            let payload = try JSONDecoder().decode(SteamWishlistResponse.self, from: data)
            let appIDs = payload.response.items?.map(\.appid) ?? []
            return Array(Set(appIDs)).sorted()
        } catch {
            throw SteamWebAPIError.decodingFailed
        }
    }
}

private struct SteamWishlistResponse: Decodable {
    let response: SteamWishlistResponseBody
}

private struct SteamWishlistResponseBody: Decodable {
    let items: [SteamWishlistItem]?
}

private struct SteamWishlistItem: Decodable {
    let appid: Int
}
