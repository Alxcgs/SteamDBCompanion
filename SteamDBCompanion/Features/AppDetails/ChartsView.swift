import SwiftUI

public struct ChartsView: View {
    let priceHistory: PriceHistory?
    let playerTrend: PlayerTrend?

    public init(priceHistory: PriceHistory?, playerTrend: PlayerTrend?) {
        self.priceHistory = priceHistory
        self.playerTrend = playerTrend
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let history = priceHistory, !history.points.isEmpty {
                    GlassCard {
                        PriceHistoryChartView(history: history)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    EmptyStateCard(text: "Price history not available.")
                }

                if let trend = playerTrend, !trend.points.isEmpty {
                    GlassCard {
                        PlayerTrendChartView(trend: trend)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    EmptyStateCard(text: "Player trend not available.")
                }
            }
            .padding()
        }
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EmptyStateCard: View {
    let text: String

    var body: some View {
        GlassCard {
            Text(text)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ChartsView(priceHistory: PriceHistory(appID: 730, currency: "USD", points: []), playerTrend: PlayerTrend(appID: 730, points: []))
}
