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
                if viewModel.trackedApps.isEmpty && viewModel.steamNews.isEmpty && viewModel.wishlistNews.isEmpty {
                    ContentStatusView(
                        kind: .loading,
                        title: L10n.tr("updates.loading", fallback: "Checking updates..."),
                        message: L10n.tr("updates.loading_hint", fallback: "Refreshing tracked apps, alerts, and news.")
                    )
                } else {
                    updatesList
                        .overlay(alignment: .top) {
                            ProgressView(L10n.tr("updates.refreshing", fallback: "Refreshing..."))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 8)
                        }
                }
            } else {
                updatesList
            }
        }
        .navigationTitle(L10n.tr("updates.title", fallback: "Updates"))
        .navigationDestination(for: SteamApp.self) { app in
            AppDetailView(appID: app.id, dataSource: dataSource)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.tr("common.refresh", fallback: "Refresh")) {
                    Task { await viewModel.refresh() }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    WebFallbackShellView(url: AppURLs.steamStoreNews, title: L10n.tr("updates.steam_news", fallback: "Steam News"))
                } label: {
                    Image(systemName: "newspaper")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.tr("common.clear", fallback: "Clear")) {
                    alertEngine.clearHistory()
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
    }

    private var updatesList: some View {
        List {
                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Section(L10n.tr("updates.status_section", fallback: "Status")) {
                            ContentStatusView(
                                kind: .error,
                                title: L10n.tr("updates.error_title", fallback: "Refresh failed"),
                                message: error,
                                actionTitle: L10n.tr("common.retry", fallback: "Retry")
                            ) {
                                Task { await viewModel.refresh() }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }

                    if let partialLoadMessage = viewModel.partialLoadMessage, !partialLoadMessage.isEmpty {
                        Section(L10n.tr("updates.status_section", fallback: "Status")) {
                            ContentStatusView(
                                kind: .info,
                                title: L10n.tr("updates.partial_title", fallback: "Partially refreshed"),
                                message: partialLoadMessage
                            )
                            .listRowBackground(Color.clear)
                        }
                    }

                    if !alertEngine.latestDiffs.isEmpty {
                        Section(L10n.tr("updates.new_changes", fallback: "New Changes")) {
                            ForEach(alertEngine.latestDiffs) { diff in
                                DiffRow(diff: diff)
                            }
                        }
                    }

                    Section(L10n.tr("updates.history_section", fallback: "History")) {
                        if alertEngine.history.isEmpty {
                            Text(L10n.tr("updates.no_changes", fallback: "No changes detected yet."))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(alertEngine.history) { diff in
                                DiffRow(diff: diff)
                            }
                        }
                    }

                    Section(L10n.tr("updates.tracked_apps", fallback: "Tracked Apps")) {
                        if viewModel.trackedApps.isEmpty {
                            Text(L10n.tr("updates.tracked_apps_empty", fallback: "Add apps to your wishlist to track updates."))
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

                    Section(L10n.tr("updates.wishlist_news", fallback: "Wishlist News")) {
                        if viewModel.wishlistNews.isEmpty {
                            Text(L10n.tr("updates.wishlist_news_empty", fallback: "No wishlist-specific news yet. Sign in and sync wishlist to get personalized updates."))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.wishlistNews) { item in
                                NavigationLink {
                                    WebFallbackShellView(url: item.url, title: L10n.tr("updates.wishlist_news", fallback: "Wishlist News"))
                                } label: {
                                    newsRow(item: item)
                                }
                            }
                        }
                    }

                    Section(L10n.tr("updates.steam_news", fallback: "Steam News")) {
                        if viewModel.steamNews.isEmpty {
                            Text(L10n.tr("updates.news_empty", fallback: "No news loaded yet. Pull to refresh."))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.steamNews) { item in
                                NavigationLink {
                                    WebFallbackShellView(url: item.url, title: L10n.tr("updates.steam_news", fallback: "Steam News"))
                                } label: {
                                    newsRow(item: item)
                                }
                            }
                        }
                    }

                    Section(L10n.tr("updates.background_policy", fallback: "Background Policy")) {
                        Text(L10n.tr("updates.background_policy_text", fallback: "This build uses free in-app alerts without APNs. Updates are checked on refresh/open."))
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

private extension UpdatesView {
    @ViewBuilder
    func newsRow(item: SteamNewsItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let publishedAt = item.publishedAt {
                    Text(publishedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let appID = item.appID {
                    Text("#\(appID)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
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
        case .priceDrop: return L10n.tr("updates.diff.price_drop", fallback: "Price Drop")
        case .priceRise: return L10n.tr("updates.diff.price_rise", fallback: "Price Rise")
        case .playerSpike: return L10n.tr("updates.diff.player_spike", fallback: "Player Spike")
        case .playerDrop: return L10n.tr("updates.diff.player_drop", fallback: "Player Drop")
        case .unknown: return L10n.tr("updates.diff.update", fallback: "Update")
        }
    }

    private func formatted(_ value: Double) -> String {
        if diff.type == .priceDrop || diff.type == .priceRise {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        }
        return "\(Int(value))"
    }
}
