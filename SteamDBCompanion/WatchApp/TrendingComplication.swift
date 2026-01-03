import SwiftUI
import WidgetKit

// MARK: - Watch Complications

struct TrendingComplication: Widget {
    let kind: String = "TrendingComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Trending")
        .description("See trending Steam games")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let game: TrendingGame?
    let playerCount: Int
}

struct TrendingGame: Codable {
    let id: Int
    let name: String
    let players: Int
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: Date(),
            game: TrendingGame(id: 730, name: "CS2", players: 1_200_000),
            playerCount: 1_200_000
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        Task {
            let game = await fetchTrendingGame()
            let entry = ComplicationEntry(
                date: Date(),
                game: game,
                playerCount: game?.players ?? 0
            )
            
            // Update every hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchTrendingGame() async -> TrendingGame? {
        // In production, fetch from shared container or network
        return TrendingGame(id: 730, name: "CS2", players: 1_200_000)
    }
}

// MARK: - Complication Views

struct ComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: ComplicationEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView(entry: entry)
        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        default:
            CircularComplicationView(entry: entry)
        }
    }
}

struct CircularComplicationView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                Text(formatNumber(entry.playerCount))
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }
}

struct RectangularComplicationView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Trending")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let game = entry.game {
                    Text(game.name)
                        .font(.caption.bold())
                    Text(formatNumber(game.players))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InlineComplicationView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        if let game = entry.game {
            Text("🎮 \(game.name): \(formatNumber(game.players))")
                .font(.caption2)
        } else {
            Text("🎮 Steam Trending")
        }
    }
}

struct CornerComplicationView: View {
    let entry: ComplicationEntry
    
    var body: some View {
        Text(formatNumber(entry.playerCount))
            .font(.system(size: 16, weight: .bold))
            .widgetLabel {
                Image(systemName: "chart.line.uptrend.xyaxis")
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

#Preview("Circular", as: .accessoryCircular) {
    TrendingComplication()
} timeline: {
    ComplicationEntry(
        date: Date(),
        game: TrendingGame(id: 730, name: "CS2", players: 1_200_000),
        playerCount: 1_200_000
    )
}

#Preview("Rectangular", as: .accessoryRectangular) {
    TrendingComplication()
} timeline: {
    ComplicationEntry(
        date: Date(),
        game: TrendingGame(id: 730, name: "CS2", players: 1_200_000),
        playerCount: 1_200_000
    )
}
