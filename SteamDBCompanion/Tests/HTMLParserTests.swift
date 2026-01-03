import XCTest
@testable import SteamDBCompanion

final class HTMLParserTests: XCTestCase {
    
    var parser: HTMLParser!
    
    override func setUp() {
        super.setUp()
        parser = HTMLParser()
    }
    
    func testParseTrending() throws {
        let html = """
        <table class="table-products">
            <tbody>
                <tr data-appid="730">
                    <td></td>
                    <td></td>
                    <td><a href="/app/730/">Counter-Strike 2</a></td>
                    <td>Free</td>
                </tr>
                <tr data-appid="271590">
                    <td></td>
                    <td></td>
                    <td><a href="/app/271590/">Grand Theft Auto V</a></td>
                    <td>$29.99</td>
                </tr>
            </tbody>
        </table>
        """
        
        let apps = try parser.parseTrending(html: html)
        
        XCTAssertEqual(apps.count, 2)
        XCTAssertEqual(apps[0].id, 730)
        XCTAssertEqual(apps[0].name, "Counter-Strike 2")
        XCTAssertNil(apps[0].price) // Free
        
        XCTAssertEqual(apps[1].id, 271590)
        XCTAssertEqual(apps[1].name, "Grand Theft Auto V")
        XCTAssertEqual(apps[1].price?.current, 29.99)
    }
    
    func testParseAppDetails() throws {
        let html = """
        <h1 itemprop="name">Half-Life 3</h1>
        <div class="header-description">The long awaited sequel.</div>
        <div class="app-chart-numbers">
            <strong>1,000,000</strong> playing now
        </div>
        <div class="price-line">
            <div class="price">$59.99</div>
        </div>
        """
        
        let app = try parser.parseAppDetails(html: html, appID: 123)
        
        XCTAssertEqual(app.id, 123)
        XCTAssertEqual(app.name, "Half-Life 3")
        XCTAssertEqual(app.playerStats?.currentPlayers, 1000000)
        XCTAssertEqual(app.price?.current, 59.99)
    }
}
