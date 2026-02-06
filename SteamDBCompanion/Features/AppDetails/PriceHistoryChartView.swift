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
            .padding(.trailing, 26)
            
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

public struct PriceHistoryDetailView: View {
    private let history: PriceHistory
    private let appName: String
    private let zoomPresets: [TimeInterval?] = [7 * 86_400, 30 * 86_400, 90 * 86_400, 180 * 86_400, 365 * 86_400, nil]
    private let zoomLabels = ["7D", "1M", "3M", "6M", "1Y", "ALL"]

    @State private var selectedDate: Date?
    @State private var zoomIndex: Int = 2

    public init(history: PriceHistory, appName: String) {
        self.history = history
        self.appName = appName
        if history.points.count < 15 {
            _zoomIndex = State(initialValue: 5)
        }
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appName)
                                .font(.headline)
                                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                            Text("Price history")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectionSummary)
                                .font(.subheadline.bold())
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCard {
                        if filteredPoints.isEmpty {
                            Text("No chart data available")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 260)
                        } else {
                            Chart(filteredPoints) { point in
                                AreaMark(
                                    x: .value("Date", point.date),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            LiquidGlassTheme.Colors.neonPrimary.opacity(0.25),
                                            LiquidGlassTheme.Colors.neonPrimary.opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                                if let selectedPoint, selectedPoint.id == point.id {
                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Price", point.price)
                                    )
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                    .symbolSize(90)
                                }
                            }
                            .chartXSelection(value: $selectedDate)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine()
                                        .foregroundStyle(Color.white.opacity(0.08))
                                    AxisValueLabel(format: .dateTime.month().day())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisGridLine()
                                        .foregroundStyle(Color.white.opacity(0.08))
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(height: 280)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Button {
                                    zoomOut()
                                } label: {
                                    Image(systemName: "minus.magnifyingglass")
                                }
                                .buttonStyle(.plain)
                                .disabled(zoomIndex == zoomPresets.count - 1)

                                Text("Zoom")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                                Button {
                                    zoomIn()
                                } label: {
                                    Image(systemName: "plus.magnifyingglass")
                                }
                                .buttonStyle(.plain)
                                .disabled(zoomIndex == 0)

                                Spacer()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(zoomLabels.indices, id: \.self) { index in
                                        Button {
                                            zoomIndex = index
                                        } label: {
                                            Text(zoomLabels[index])
                                                .font(.caption.bold())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(index == zoomIndex ? LiquidGlassTheme.Colors.neonPrimary.opacity(0.2) : Color.white.opacity(0.08))
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            Text("Tap or drag on the chart to inspect the exact price at that date.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Price Chart")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedPoints: [PriceHistoryPoint] {
        history.points.sorted(by: { $0.date < $1.date })
    }

    private var filteredPoints: [PriceHistoryPoint] {
        guard let lastPoint = sortedPoints.last else { return [] }
        guard let window = zoomPresets[zoomIndex] else { return sortedPoints }
        let startDate = lastPoint.date.addingTimeInterval(-window)
        let scoped = sortedPoints.filter { $0.date >= startDate }
        return scoped.isEmpty ? sortedPoints : scoped
    }

    private var selectedPoint: PriceHistoryPoint? {
        guard !filteredPoints.isEmpty else { return nil }
        guard let selectedDate else { return filteredPoints.last }
        return filteredPoints.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(selectedDate)) < abs(rhs.date.timeIntervalSince(selectedDate))
        }
    }

    private var selectionSummary: String {
        guard let point = selectedPoint else { return "No price data" }
        let dateText = point.date.formatted(date: .abbreviated, time: .omitted)
        return "\(dateText) • \(formatPrice(point.price))"
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = history.currency
        return formatter.string(from: NSNumber(value: value)) ?? "\(history.currency) \(String(format: "%.2f", value))"
    }

    private func zoomIn() {
        guard zoomIndex > 0 else { return }
        zoomIndex -= 1
    }

    private func zoomOut() {
        guard zoomIndex < zoomPresets.count - 1 else { return }
        zoomIndex += 1
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
