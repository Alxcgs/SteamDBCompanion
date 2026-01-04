import SwiftUI

public struct BrowseView: View {
    private let dataSource: SteamDBDataSource

    public init(dataSource: SteamDBDataSource) {
        self.dataSource = dataSource
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "Browse SteamDB", icon: "sparkles")

                    NavigationLink {
                        SearchView(dataSource: dataSource)
                    } label: {
                        SectionRow(title: "Search Apps", subtitle: "Find any Steam app", icon: "magnifyingglass")
                    }

                    NavigationLink {
                        AppsListView(mode: .trending, dataSource: dataSource)
                    } label: {
                        SectionRow(title: "Trending", subtitle: "Hot right now", icon: "chart.line.uptrend.xyaxis")
                    }

                    NavigationLink {
                        AppsListView(mode: .topSellers, dataSource: dataSource)
                    } label: {
                        SectionRow(title: "Top Sellers", subtitle: "Best-selling games", icon: "crown.fill")
                    }

                    NavigationLink {
                        AppsListView(mode: .mostPlayed, dataSource: dataSource)
                    } label: {
                        SectionRow(title: "Most Played", subtitle: "Highest player counts", icon: "person.2.fill")
                    }

                    NavigationLink {
                        AppLookupView(dataSource: dataSource)
                    } label: {
                        SectionRow(title: "App Sections", subtitle: "Packages, depots, badges & more", icon: "rectangle.stack.fill")
                    }

                    NavigationLink {
                        SteamDBWebView()
                    } label: {
                        SectionRow(title: "Open SteamDB Website", subtitle: "Full site experience", icon: "globe")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BrowseView(dataSource: MockSteamDBDataSource())
    }
}
