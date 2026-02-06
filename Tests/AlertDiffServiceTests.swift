import XCTest
@testable import SteamDBCompanion

final class AlertDiffServiceTests: XCTestCase {
    func testPriceDropAndRiseDiffs() {
        let service = DefaultAlertDiffService()
        let previous = [
            AppSnapshot(appID: 1, name: "One", price: 20, players: 100),
            AppSnapshot(appID: 2, name: "Two", price: 10, players: 100)
        ]
        let current = [
            AppSnapshot(appID: 1, name: "One", price: 15, players: 100),
            AppSnapshot(appID: 2, name: "Two", price: 12, players: 100)
        ]

        let diffs = service.detectDiffs(previous: previous, current: current)
        XCTAssertEqual(diffs.count, 2)
        XCTAssertTrue(diffs.contains(where: { $0.type == .priceDrop && $0.appID == 1 }))
        XCTAssertTrue(diffs.contains(where: { $0.type == .priceRise && $0.appID == 2 }))
    }

    func testPlayerThresholdDiffs() {
        let service = DefaultAlertDiffService(playerThreshold: 0.2)
        let previous = [AppSnapshot(appID: 7, name: "Seven", price: nil, players: 100)]
        let current = [AppSnapshot(appID: 7, name: "Seven", price: nil, players: 130)]

        let diffs = service.detectDiffs(previous: previous, current: current)
        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.type, .playerSpike)
        XCTAssertEqual(diffs.first?.appID, 7)
    }
}
