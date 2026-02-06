import XCTest
@testable import SteamDBCompanion

final class HomeViewModelTests: XCTestCase {
    
    var viewModel: HomeViewModel!
    var mockDataSource: MockSteamDBDataSource!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockSteamDBDataSource()
        viewModel = HomeViewModel(dataSource: mockDataSource)
    }
    
    @MainActor
    func testLoadDataSuccess() async {
        // Given
        XCTAssertTrue(viewModel.trendingApps.isEmpty)
        XCTAssertTrue(viewModel.topSellers.isEmpty)
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertFalse(viewModel.trendingApps.isEmpty, "Trending apps should be loaded")
        XCTAssertFalse(viewModel.topSellers.isEmpty, "Top sellers should be loaded")
        XCTAssertNil(viewModel.errorMessage, "No error should occur")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")
    }
    
    @MainActor
    func testLoadingState() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When - start loading
        Task {
            await viewModel.loadData()
        }
        
        // Give time for loading state to set
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Then - eventually completes
        await viewModel.loadData()
        XCTAssertFalse(viewModel.isLoading)
    }
}

final class SearchViewModelTests: XCTestCase {
    
    var viewModel: SearchViewModel!
    var mockDataSource: MockSteamDBDataSource!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockSteamDBDataSource()
        viewModel = SearchViewModel(dataSource: mockDataSource)
    }
    
    @MainActor
    func testEmptyQuery() {
        // Given
        viewModel.query = ""
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
    }
    
    @MainActor
    func testSearchDebouncing() async {
        // Given
        let query = "Counter"
        
        // When
        viewModel.query = query
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s
        
        // Then
        XCTAssertFalse(viewModel.results.isEmpty, "Results should be populated after debounce")
    }
}

final class AppDetailViewModelTests: XCTestCase {
    
    var viewModel: AppDetailViewModel!
    var mockDataSource: MockSteamDBDataSource!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockSteamDBDataSource()
        viewModel = AppDetailViewModel(appID: 730, dataSource: mockDataSource)
    }
    
    @MainActor
    func testLoadDetailsSuccess() async {
        // Given
        XCTAssertNil(viewModel.app)
        
        // When
        await viewModel.loadDetails()
        
        // Then
        XCTAssertNotNil(viewModel.app, "App should be loaded")
        XCTAssertNotNil(viewModel.priceHistory, "Price history should be loaded")
        XCTAssertNotNil(viewModel.playerTrend, "Player trend should be loaded")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testCorrectAppID() async {
        // When
        await viewModel.loadDetails()
        
        // Then
        XCTAssertEqual(viewModel.app?.id, 730, "Should load correct app ID")
    }
}

final class WishlistManagerTests: XCTestCase {
    
    var wishlistManager: WishlistManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        wishlistManager = WishlistManager()
        // Clear any existing data
        wishlistManager.wishlist.removeAll()
    }
    
    @MainActor
    func testToggleWishlist() {
        // Given
        let appID = 730
        XCTAssertFalse(wishlistManager.isWishlisted(appID: appID))
        
        // When - add to wishlist
        wishlistManager.toggleWishlist(appID: appID)
        
        // Then
        XCTAssertTrue(wishlistManager.isWishlisted(appID: appID))
        
        // When - remove from wishlist
        wishlistManager.toggleWishlist(appID: appID)
        
        // Then
        XCTAssertFalse(wishlistManager.isWishlisted(appID: appID))
    }
    
    @MainActor
    func testMultipleItems() {
        // Given
        let appIDs = [730, 570, 271590]
        
        // When
        appIDs.forEach { wishlistManager.toggleWishlist(appID: $0) }
        
        // Then
        XCTAssertEqual(wishlistManager.wishlist.count, 3)
        appIDs.forEach { appID in
            XCTAssertTrue(wishlistManager.isWishlisted(appID: appID))
        }
    }
}
