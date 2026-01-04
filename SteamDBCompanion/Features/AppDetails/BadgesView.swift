import SwiftUI

public struct BadgesView: View {
    let badges: [SteamBadge]

    public init(badges: [SteamBadge]) {
        self.badges = badges
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if badges.isEmpty {
                    EmptyStateCard(text: "No badges found.")
                } else {
                    ForEach(badges) { badge in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(badge.name)
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                                if let level = badge.level, !level.isEmpty {
                                    Text(level)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let rarity = badge.rarity, !rarity.isEmpty {
                                    Text("Rarity: \(rarity)")
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
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BadgesView(badges: [
        SteamBadge(id: 1, name: "Collector Badge", level: "Level 1", rarity: "Common")
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
