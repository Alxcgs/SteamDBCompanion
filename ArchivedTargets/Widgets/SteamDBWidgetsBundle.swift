import WidgetKit

@main
struct SteamDBWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TrendingGamesWidget()
        
        // Apple Watch Complications (requires watchOS target)
        #if os(watchOS)
        TrendingComplication()
        #endif
    }
}
