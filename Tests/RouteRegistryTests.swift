import XCTest
@testable import SteamDBCompanion

final class RouteRegistryTests: XCTestCase {
    func testExactRouteResolvesToNative() {
        let registry = RouteRegistry()
        let resolution = registry.resolve(path: "/search")

        XCTAssertEqual(resolution.descriptor.mode, .native)
        XCTAssertEqual(resolution.descriptor.group, .search)
    }

    func testParameterizedRouteResolvesToNativeApp() {
        let registry = RouteRegistry()
        let resolution = registry.resolve(path: "/app/730")

        XCTAssertEqual(resolution.descriptor.path, "/app/:id")
        XCTAssertEqual(resolution.descriptor.mode, .native)
    }

    func testUnknownRouteFallsBackToWeb() {
        let registry = RouteRegistry()
        let resolution = registry.resolve(path: "/unknown/path")

        XCTAssertEqual(resolution.descriptor.mode, .webFallback)
        XCTAssertEqual(resolution.normalizedPath, "/unknown/path")
    }

    func testFullURLNormalization() {
        let registry = RouteRegistry()
        let resolution = registry.resolve(path: "https://steamdb.info/tags/")

        XCTAssertEqual(resolution.normalizedPath, "/tags")
        XCTAssertEqual(resolution.descriptor.mode, .webFallback)
    }

    func testUtilityRoutesCarryFallbackOverrides() {
        let registry = RouteRegistry()

        let events = registry.resolve(path: "/events")
        XCTAssertEqual(events.descriptor.webURLOverride, "https://steamdb.info/sales/history/")
        XCTAssertEqual(events.descriptor.fallbackWebURL, "https://store.steampowered.com/news/")

        let wishlist = registry.resolve(path: "/wishlist")
        XCTAssertEqual(wishlist.descriptor.webURLOverride, "https://store.steampowered.com/wishlist/")
        XCTAssertNil(wishlist.descriptor.fallbackWebURL)
    }
}
