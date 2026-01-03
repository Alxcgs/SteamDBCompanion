import SwiftUI
import Charts

public struct PlayerTrendChartView: View {
    
    let trend: PlayerTrend
    
    public init(trend: PlayerTrend) {
        self.trend = trend
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Player Activity")
                        .font(.headline)
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                    
                    if !trend.points.isEmpty {
                        Text("Last 24 Hours")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Stats
                if let peak = trend.peakPlayers {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Peak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(formatNumber(peak.playerCount))")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                    }
                }
            }
            
            // Chart
            if trend.points.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No player data available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                Chart(trend.points) { point in
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Players", point.playerCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                LiquidGlassTheme.Colors.neonSecondary.opacity(0.4),
                                LiquidGlassTheme.Colors.neonSecondary.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Players", point.playerCount)
                    )
                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.hour())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 180)
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

#Preview {
    let mockTrend = PlayerTrend(
        appID: 730,
        points: (0..<24).map { i in
            PlayerCountPoint(
                date: Calendar.current.date(byAdding: .hour, value: -i, to: Date())!,
                playerCount: Int.random(in: 80000...150000)
            )
        }
    )
    
    ZStack {
        Color.black.ignoresSafeArea()
        GlassCard {
            PlayerTrendChartView(trend: mockTrend)
        }
        .padding()
    }
}
