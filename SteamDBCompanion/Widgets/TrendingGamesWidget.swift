import WidgetKit
import SwiftUI

struct TrendingGamesWidget: Widget {
    let kind: String = "TrendingGamesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrendingGamesProvider()) { entry in
            TrendingGamesWidgetView(entry: entry)
        }
        .configurationDisplayName("Trending Games")
        .description("See what's trending on Steam right now")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct TrendingGamesEntry: TimelineEntry {
    let date: Date
    let games: [TrendingGame]
}

struct TrendingGame: Identifiable {
    let id: Int
    let name: String
    let players: Int
}

struct TrendingGamesProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrendingGamesEntry {
        TrendingGamesEntry(
            date: Date(),
            games: [
                TrendingGame(id: 730, name: "Counter-Strike 2", players: 1_200_000),
                TrendingGame(id: 570, name: "Dota 2", players: 600_000)
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TrendingGamesEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TrendingGamesEntry>) -> Void) {
        // Fetch trending games
        Task {
            let games = await fetchTrendingGames()
            let entry = TrendingGamesEntry(date: Date(), games: games)
            
            // Update every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchTrendingGames() async -> [TrendingGame] {
        // In production, fetch from shared data container or network
        // For now, return mock data
        return [
            TrendingGame(id: 730, name: "Counter-Strike 2", players: 1_200_000),
            TrendingGame(id: 570, name: "Dota 2", players: 600_000),
            TrendingGame(id: 271590, name: "GTA V", players: 150_000)
        ]
    }
}

struct TrendingGamesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TrendingGamesEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(game: entry.games.first)
        case .systemMedium:
            MediumWidgetView(games: Array(entry.games.prefix(3)))
        case .accessoryRectangular:
            LockScreenRectangularView(games: Array(entry.games.prefix(2)))
        case .accessoryCircular:
            LockScreenCircularView(game: entry.games.first)
        default:
            SmallWidgetView(game: entry.games.first)
        }
    }
}

// MARK: - Widget Variants

struct SmallWidgetView: View {
    let game: TrendingGame?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let game = game {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    Text(game.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text(formatNumber(game.players))
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding()
            }
        }
    }
}

struct MediumWidgetView: View {
    let games: [TrendingGame]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                    Text("Trending on Steam")
                        .font(.headline.bold())
                    Spacer()
                    
                    // iOS 17+ Interactive refresh button
                    if #available(iOS 17.0, *) {
                        Button(intent: RefreshDataIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .tint(.white)
                    }
                }
                .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(games) { game in
                        HStack {
                            Text(game.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text(formatNumber(game.players))
                                    .font(.caption)
                            }
                            
                            // iOS 17+ Interactive wishlist button
                            if #available(iOS 17.0, *) {
                                Button(intent: ToggleWishlistIntent(appID: game.id, appName: game.name)) {
                                    Image(systemName: "heart")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .tint(.white.opacity(0.8))
                            }
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
    }
}

struct LockScreenRectangularView: View {
    let games: [TrendingGame]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Trending", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.bold())
            
            ForEach(games) { game in
                HStack {
                    Text(game.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text(formatNumber(game.players))
                        .font(.caption2)
                }
            }
        }
    }
}

struct LockScreenCircularView: View {
    let game: TrendingGame?
    
    var body: some View {
        if let game = game {
            VStack(spacing: 2) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                Text(formatNumber(game.players))
                    .font(.caption2.bold())
            }
        }
    }
}

// MARK: - Helper

private func formatNumber(_ number: Int) -> String {
    if number >= 1_000_000 {
        return String(format: "%.1fM", Double(number) / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.0fK", Double(number) / 1_000)
    }
    return "\(number)"
}

#Preview(as: .systemSmall) {
    TrendingGamesWidget()
} timeline: {
    TrendingGamesEntry(
        date: Date(),
        games: [
            TrendingGame(id: 730, name: "Counter-Strike 2", players: 1_200_000)
        ]
    )
}
