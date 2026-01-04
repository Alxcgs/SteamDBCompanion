import SwiftUI

public struct PackagesView: View {
    let packages: [SteamPackage]

    public init(packages: [SteamPackage]) {
        self.packages = packages
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if packages.isEmpty {
                    EmptyStateCard(text: "No packages found.")
                } else {
                    ForEach(packages) { package in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(package.name)
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                                HStack(spacing: 12) {
                                    Text("Package ID: \(package.id)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if let type = package.type, !type.isEmpty {
                                        Text(type)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }

                                if let price = package.price {
                                    Text(price.formatted)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                } else {
                                    Text("Free")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Packages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PackagesView(packages: [
        SteamPackage(id: 12345, name: "Standard Edition", price: PriceInfo(current: 29.99, currency: "USD", discountPercent: 0, initial: 29.99), type: "Game")
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
