import SwiftUI

public struct RouteHostView: View {
    private let dataSource: SteamDBDataSource
    private let resolution: RouteResolution

    public init(path: String, dataSource: SteamDBDataSource, resolver: RouteResolver = RouteRegistry.shared) {
        self.dataSource = dataSource
        self.resolution = resolver.resolve(path: path)
    }

    public var body: some View {
        content
            .navigationTitle(resolution.descriptor.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if resolution.descriptor.mode == .webFallback {
            let primaryURL = URL(string: resolution.descriptor.webURLOverride ?? "https://steamdb.info\(resolution.normalizedPath)")
            let fallbackURL = resolution.descriptor.fallbackWebURL.flatMap(URL.init(string:))
            if let primaryURL {
                WebFallbackShellView(
                    url: primaryURL,
                    title: resolution.descriptor.title,
                    fallbackURL: fallbackURL
                )
            } else {
                WebFallbackShellView(path: resolution.normalizedPath, title: resolution.descriptor.title)
            }
        } else if let appID = extractAppID(from: resolution.normalizedPath) {
            AppDetailView(appID: appID, dataSource: dataSource)
        } else if resolution.normalizedPath == "/" {
            HomeView(dataSource: dataSource)
        } else if resolution.normalizedPath == "/search" || resolution.normalizedPath == "/instantsearch" {
            SearchView(dataSource: dataSource)
        } else {
            NativeRouteCollectionView(
                title: resolution.descriptor.title,
                routePath: resolution.normalizedPath,
                dataSource: dataSource
            )
        }
    }

    private func extractAppID(from path: String) -> Int? {
        let components = path.split(separator: "/").map(String.init)
        guard components.count >= 2 else { return nil }
        guard components[0] == "app" else { return nil }
        return Int(components[1])
    }
}

private struct NativeRouteCollectionView: View {
    let title: String
    let routePath: String
    let dataSource: SteamDBDataSource

    @State private var apps: [SteamApp] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("\(L10n.tr("common.loading", fallback: "Loading...")) \(title)...")
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(LiquidGlassTheme.Colors.neonWarning)
                    Text(errorMessage)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(apps) { app in
                    NavigationLink {
                        AppDetailView(appID: app.id, dataSource: dataSource)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.headline)
                                Text("#\(app.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let price = app.price {
                                Text(price.formatted)
                                    .font(.subheadline.bold())
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let kind = collectionKind(for: routePath) {
                apps = try await dataSource.fetchCollection(kind: kind)
            } else {
                apps = try await dataSource.fetchTrending()
            }
        } catch {
            errorMessage = "\(L10n.tr("routes.error_load", fallback: "Failed to load")) \(title): \(error.localizedDescription)"
        }
    }

    private func collectionKind(for path: String) -> CollectionKind? {
        switch path {
        case "/sales": return .sales
        case "/charts": return .charts
        case "/calendar": return .calendar
        case "/pricechanges": return .pricechanges
        case "/upcoming": return .upcoming
        case "/freepackages": return .freepackages
        case "/bundles": return .bundles
        case "/top-rated": return .topRated
        case "/topsellers/global": return .topSellersGlobal
        case "/topsellers/weekly": return .topSellersWeekly
        case "/mostfollowed": return .mostFollowed
        case "/mostwished": return .mostWished
        case "/wishlists": return .wishlists
        case "/dailyactiveusers": return .dailyActiveUsers
        default: return nil
        }
    }
}
