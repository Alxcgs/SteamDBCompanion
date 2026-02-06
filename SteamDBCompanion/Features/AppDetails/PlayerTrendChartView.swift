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
            .padding(.trailing, 26)
            
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

public struct PlayerTrendDetailView: View {
    private let trend: PlayerTrend
    private let appName: String
    private let zoomPresets: [TimeInterval?] = [24 * 3_600, 7 * 86_400, 30 * 86_400, 90 * 86_400, nil]
    private let zoomLabels = ["24H", "7D", "30D", "90D", "ALL"]

    @State private var selectedDate: Date?
    @State private var zoomIndex: Int = 1

    public init(trend: PlayerTrend, appName: String) {
        self.trend = trend
        self.appName = appName
        if trend.points.count < 20 {
            _zoomIndex = State(initialValue: zoomLabels.count - 1)
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
                            Text("Player activity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectionSummary)
                                .font(.subheadline.bold())
                                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCard {
                        if filteredPoints.isEmpty {
                            Text("No player trend data available")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 260)
                        } else {
                            Chart(filteredPoints) { point in
                                AreaMark(
                                    x: .value("Date", point.date),
                                    y: .value("Players", point.playerCount)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            LiquidGlassTheme.Colors.neonSecondary.opacity(0.3),
                                            LiquidGlassTheme.Colors.neonSecondary.opacity(0.08)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Players", point.playerCount)
                                )
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                                if let selectedPoint, selectedPoint.id == point.id {
                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Players", point.playerCount)
                                    )
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
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
                                                .background(index == zoomIndex ? LiquidGlassTheme.Colors.neonSecondary.opacity(0.25) : Color.white.opacity(0.08))
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            Text("Tap or drag on the chart to inspect the exact player count at that date.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Player Chart")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedPoints: [PlayerCountPoint] {
        trend.points.sorted(by: { $0.date < $1.date })
    }

    private var filteredPoints: [PlayerCountPoint] {
        guard let lastPoint = sortedPoints.last else { return [] }
        guard let window = zoomPresets[zoomIndex] else { return sortedPoints }
        let startDate = lastPoint.date.addingTimeInterval(-window)
        let scoped = sortedPoints.filter { $0.date >= startDate }
        return scoped.isEmpty ? sortedPoints : scoped
    }

    private var selectedPoint: PlayerCountPoint? {
        guard !filteredPoints.isEmpty else { return nil }
        guard let selectedDate else { return filteredPoints.last }
        return filteredPoints.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(selectedDate)) < abs(rhs.date.timeIntervalSince(selectedDate))
        }
    }

    private var selectionSummary: String {
        guard let point = selectedPoint else { return "No player data" }
        let dateText = point.date.formatted(date: .abbreviated, time: .shortened)
        return "\(dateText) • \(formatNumber(point.playerCount)) players"
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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
