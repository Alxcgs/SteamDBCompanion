import SwiftUI

public struct UpdatesView: View {
    @EnvironmentObject private var alertEngine: InAppAlertEngine
    @EnvironmentObject private var wishlistManager: WishlistManager
    @StateObject private var viewModel: UpdatesViewModel
    private let dataSource: SteamDBDataSource

    public init(dataSource: SteamDBDataSource, wishlistManager: WishlistManager, alertEngine: InAppAlertEngine) {
        self.dataSource = dataSource
        _viewModel = StateObject(
            wrappedValue: UpdatesViewModel(
                dataSource: dataSource,
                wishlistManager: wishlistManager,
                alertEngine: alertEngine
            )
        )
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Checking updates...")
            } else {
                List {
                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Section("Status") {
                            Text(error)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonError)
                        }
                    }

                    if !alertEngine.latestDiffs.isEmpty {
                        Section("New Changes") {
                            ForEach(alertEngine.latestDiffs) { diff in
                                DiffRow(diff: diff)
                            }
                        }
                    }

                    Section("History") {
                        if alertEngine.history.isEmpty {
                            Text("No changes detected yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(alertEngine.history) { diff in
                                DiffRow(diff: diff)
                            }
                        }
                    }

                    Section("Tracked Apps") {
                        if viewModel.trackedApps.isEmpty {
                            Text("Add apps to your wishlist to track updates.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.trackedApps) { app in
                                NavigationLink(value: app) {
                                    HStack {
                                        Text(app.name)
                                        Spacer()
                                        if let price = app.price {
                                            Text(price.formatted)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section("Steam News") {
                        if viewModel.steamNews.isEmpty {
                            Text("No news loaded yet. Pull to refresh.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.steamNews) { item in
                                NavigationLink {
                                    WebFallbackShellView(url: item.url, title: "Steam News")
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                            .lineLimit(2)

                                        if let publishedAt = item.publishedAt {
                                            Text(publishedAt, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }

                    Section("Background Policy") {
                        Text("This build uses free in-app alerts without APNs. Updates are checked on refresh/open.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Updates")
        .navigationDestination(for: SteamApp.self) { app in
            AppDetailView(appID: app.id, dataSource: dataSource)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    WebFallbackShellView(url: URL(string: "https://store.steampowered.com/news/")!, title: "Steam News")
                } label: {
                    Image(systemName: "newspaper")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button("Clear") {
                    alertEngine.clearHistory()
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
    }
}

private struct DiffRow: View {
    let diff: AlertDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
                Text(diff.detectedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("#\(diff.appID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(formatted(diff.oldValue)) -> \(formatted(diff.newValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var label: String {
        switch diff.type {
        case .priceDrop: return "Price Drop"
        case .priceRise: return "Price Rise"
        case .playerSpike: return "Player Spike"
        case .playerDrop: return "Player Drop"
        case .unknown: return "Update"
        }
    }

    private func formatted(_ value: Double) -> String {
        if diff.type == .priceDrop || diff.type == .priceRise {
            return String(format: "$%.2f", value)
        }
        return "\(Int(value))"
    }
}
