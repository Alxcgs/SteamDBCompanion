import XCTest
@testable import SteamDBCompanion

final class AppURLsTests: XCTestCase {
    func testSteamDBPathNormalizesRelativeAndAbsolutePaths() {
        XCTAssertEqual(AppURLs.steamDB(path: "app/730").absoluteString, "https://steamdb.info/app/730")
        XCTAssertEqual(AppURLs.steamDB(path: "/charts").absoluteString, "https://steamdb.info/charts")
        XCTAssertEqual(AppURLs.steamDB(path: "").absoluteString, "https://steamdb.info/")
    }

    func testSteamStoreAppURLUsesCanonicalStoreRoute() {
        XCTAssertEqual(AppURLs.steamStoreApp(id: 730).absoluteString, "https://store.steampowered.com/app/730")
    }

    func testSteamServiceURLsAreCentralized() {
        XCTAssertEqual(AppURLs.steamStoreUserData.host, "store.steampowered.com")
        XCTAssertEqual(AppURLs.steamAppNews.path, "/ISteamNews/GetNewsForApp/v2/")
    }
}

