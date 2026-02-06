import SwiftUI
import Charts

public struct PriceHistoryChartView: View {
    
    let history: PriceHistory
    
    public init(history: PriceHistory) {
        self.history = history
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Price History")
                    .font(.headline)
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                
                Spacer()
                
                if let lowest = history.lowestPrice {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Lowest")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatPrice(lowest.price))
                            .font(.caption.bold())
                            .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                    }
                }
            }
            
            // Chart
            if history.points.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No price history available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                Chart(history.points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                LiquidGlassTheme.Colors.neonPrimary,
                                LiquidGlassTheme.Colors.neonSuccess
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                LiquidGlassTheme.Colors.neonPrimary.opacity(0.3),
                                LiquidGlassTheme.Colors.neonPrimary.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
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
                .frame(height: 200)
            }
        }
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = history.currency
        return formatter.string(from: NSNumber(value: value)) ?? "\(history.currency) \(String(format: "%.2f", value))"
    }
}

#Preview {
    let mockHistory = PriceHistory(
        appID: 123,
        currency: "USD",
        points: (0..<30).map { i in
            PriceHistoryPoint(
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                price: Double.random(in: 20...40),
                discount: Int.random(in: 0...50)
            )
        }
    )
    
    ZStack {
        Color.black.ignoresSafeArea()
        GlassCard {
            PriceHistoryChartView(history: mockHistory)
        }
        .padding()
    }
}
