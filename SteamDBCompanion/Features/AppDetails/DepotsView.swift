import SwiftUI

public struct DepotsView: View {
    let depots: [SteamDepot]

    public init(depots: [SteamDepot]) {
        self.depots = depots
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if depots.isEmpty {
                    EmptyStateCard(text: "No depots found.")
                } else {
                    ForEach(depots) { depot in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(depot.name)
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                                Text("Depot ID: \(depot.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let size = depot.size, !size.isEmpty {
                                    Text("Size: \(size)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let manifest = depot.manifest, !manifest.isEmpty {
                                    Text("Manifest: \(manifest)")
                                        .font(.caption2)
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
        .navigationTitle("Depots")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DepotsView(depots: [
        SteamDepot(id: 123456, name: "Windows Content", size: "12.3 GB", manifest: "7890123456789012345")
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
