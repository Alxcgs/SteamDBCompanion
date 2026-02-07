import XCTest
@testable import SteamDBCompanion

final class GatewayLocaleTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "steamStoreCountryCode")
        UserDefaults.standard.removeObject(forKey: "steamStoreLanguageCode")
        UserDefaults.standard.removeObject(forKey: "appLanguageMode")
        super.tearDown()
    }

    func testFetchHomeIncludesLocaleQuery() async throws {
        UserDefaults.standard.set("ua", forKey: "steamStoreCountryCode")
        UserDefaults.standard.set("uk", forKey: "steamStoreLanguageCode")

        let session = URLSession(configuration: mockConfiguration(jsonBody: """
        {"trending":[],"topSellers":[],"mostPlayed":[],"stale":false}
        """))
        let client = HTTPSteamDBGatewayClient(baseURL: URL(string: "https://example.com")!, session: session)

        _ = try await client.fetchHome()

        let requestURL = try XCTUnwrap(MockURLProtocol.requestedURL)
        XCTAssertEqual(URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "cc" })?.value, "ua")
        XCTAssertEqual(URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "l" })?.value, "uk")
    }

    func testSearchUsesAppLanguageWhenSelected() async throws {
        UserDefaults.standard.set("auto", forKey: "steamStoreCountryCode")
        UserDefaults.standard.set("en", forKey: "steamStoreLanguageCode")
        UserDefaults.standard.set("uk", forKey: "appLanguageMode")

        let session = URLSession(configuration: mockConfiguration(jsonBody: """
        {"results":[],"page":1,"total":null,"stale":false}
        """))
        let client = HTTPSteamDBGatewayClient(baseURL: URL(string: "https://example.com")!, session: session)

        _ = try await client.search(query: "cs", page: 1)

        let requestURL = try XCTUnwrap(MockURLProtocol.requestedURL)
        let items = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first(where: { $0.name == "q" })?.value, "cs")
        XCTAssertEqual(items.first(where: { $0.name == "l" })?.value, "uk")
    }

    private func mockConfiguration(jsonBody: String) -> URLSessionConfiguration {
        MockURLProtocol.requestedURL = nil
        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.requestedURL = request.url
            let data = jsonBody.data(using: .utf8) ?? Data()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}

