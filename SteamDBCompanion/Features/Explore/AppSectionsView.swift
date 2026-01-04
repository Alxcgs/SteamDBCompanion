import SwiftUI

public struct AppSectionsView: View {
    @StateObject private var viewModel: AppDetailViewModel
    private let appID: Int
    private let dataSource: SteamDBDataSource

    public init(appID: Int, dataSource: SteamDBDataSource) {
        self.appID = appID
        self.dataSource = dataSource
        _viewModel = StateObject(wrappedValue: AppDetailViewModel(appID: appID, dataSource: dataSource))
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
                    VStack(spacing: 16) {
                        SectionHeader(title: "SteamDB Sections", icon: "rectangle.stack.fill")

                        NavigationLink {
                            AppDetailView(appID: appID, dataSource: dataSource)
                        } label: {
                            SectionRow(title: "App Overview", subtitle: "Full native details", icon: "info.circle.fill")
                        }

                        NavigationLink {
                            ChartsView(priceHistory: viewModel.priceHistory, playerTrend: viewModel.playerTrend)
                        } label: {
                            SectionRow(title: "Charts", subtitle: "Price history & player trends", icon: "chart.line.uptrend.xyaxis")
                        }

                        NavigationLink {
                            PackagesView(packages: viewModel.packages)
                        } label: {
                            SectionRow(title: "Packages", subtitle: "\(viewModel.packages.count) packages", icon: "shippingbox.fill")
                        }

                        NavigationLink {
                            DepotsView(depots: viewModel.depots)
                        } label: {
                            SectionRow(title: "Depots", subtitle: "\(viewModel.depots.count) depots", icon: "tray.full.fill")
                        }

                        NavigationLink {
                            BadgesView(badges: viewModel.badges)
                        } label: {
                            SectionRow(title: "Badges", subtitle: "\(viewModel.badges.count) badges", icon: "seal.fill")
                        }

                        NavigationLink {
                            ChangelogView(entries: viewModel.changelogs)
                        } label: {
                            SectionRow(title: "Changelogs", subtitle: "\(viewModel.changelogs.count) entries", icon: "clock.arrow.circlepath")
                        }

                        NavigationLink {
                            SteamDBWebView(url: URL(string: "https://steamdb.info/app/\(appID)/")!)
                        } label: {
                            SectionRow(title: "Open on SteamDB", subtitle: "Full site view", icon: "globe")
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("App \(appID)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails()
        }
    }
}

#Preview {
    NavigationStack {
        AppSectionsView(appID: 730, dataSource: MockSteamDBDataSource())
    }
}
