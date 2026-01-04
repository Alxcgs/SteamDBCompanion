import SwiftUI

public struct AppsListView: View {
    @StateObject private var viewModel: AppsListViewModel
    private let dataSource: SteamDBDataSource

    public init(mode: AppsListMode, dataSource: SteamDBDataSource) {
        _viewModel = StateObject(wrappedValue: AppsListViewModel(mode: mode, dataSource: dataSource))
        self.dataSource = dataSource
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(LiquidGlassTheme.Colors.neonError)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.apps) { app in
                            NavigationLink(value: app) {
                                AppListRow(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .navigationDestination(for: SteamApp.self) { app in
            AppDetailView(appID: app.id, dataSource: dataSource)
        }
    }
}

private struct AppListRow: View {
    let app: SteamApp

    var body: some View {
        GlassCard(padding: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .foregroundStyle(.white.opacity(0.5))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                    HStack(spacing: 8) {
                        if let players = app.playerStats?.currentPlayers, players > 0 {
                            Label("\(players)", systemImage: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let price = app.price {
                            Text(price.formatted)
                                .font(.caption)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        } else {
                            Text("Free")
                                .font(.caption)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppsListView(mode: .trending, dataSource: MockSteamDBDataSource())
    }
}
