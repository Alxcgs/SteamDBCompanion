import SwiftUI

public struct ChangelogView: View {
    let entries: [SteamChangelogEntry]

    public init(entries: [SteamChangelogEntry]) {
        self.entries = entries
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if entries.isEmpty {
                    EmptyStateCard(text: "No changelog entries found.")
                } else {
                    ForEach(entries) { entry in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.summary)
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                                if let buildID = entry.buildID, !buildID.isEmpty {
                                    Text("Build: \(buildID)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let date = entry.date, !date.isEmpty {
                                    Text(date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Changelogs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ChangelogView(entries: [
        SteamChangelogEntry(id: "build-1001", buildID: "1001", date: "2024-04-01", summary: "Added new maps.")
    ])
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
