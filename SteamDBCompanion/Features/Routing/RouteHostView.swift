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
        if resolution.normalizedPath == "/news" {
            WebFallbackShellView(url: URL(string: "https://store.steampowered.com/news/")!, title: "Steam News")
        } else if resolution.descriptor.mode == .webFallback {
            WebFallbackShellView(path: resolution.normalizedPath, title: resolution.descriptor.title)
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
                ProgressView("Loading \(title)...")
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
                    NavigationLink(value: app) {
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
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            await load()
        }
        .navigationDestination(for: SteamApp.self) { app in
            AppDetailView(appID: app.id, dataSource: dataSource)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch routePath {
            case "/charts", "/dailyactiveusers":
                apps = try await dataSource.fetchMostPlayed()
            case "/sales", "/top-rated", "/topsellers/global", "/topsellers/weekly", "/mostfollowed", "/mostwished", "/wishlists":
                apps = try await dataSource.fetchTopSellers()
            default:
                apps = try await dataSource.fetchTrending()
            }
        } catch {
            errorMessage = "Failed to load \(title): \(error.localizedDescription)"
        }
    }
}
