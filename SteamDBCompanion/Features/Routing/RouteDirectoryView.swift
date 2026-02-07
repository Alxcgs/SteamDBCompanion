import SwiftUI

public struct RouteDirectoryView: View {
    private let dataSource: SteamDBDataSource
    private let routes: [RouteDescriptor]

    public init(dataSource: SteamDBDataSource, routes: [RouteDescriptor] = RouteRegistry.defaultDescriptors) {
        self.dataSource = dataSource
        self.routes = routes
    }

    public var body: some View {
        List {
            ForEach(groupedRoutes.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { group in
                if let entries = groupedRoutes[group] {
                    Section(groupTitle(group)) {
                        ForEach(entries.filter(\.enabled).filter { !$0.path.contains(":") }) { descriptor in
                            NavigationLink {
                                RouteHostView(path: descriptor.path, dataSource: dataSource)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(descriptor.title)
                                        Text(descriptor.path)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    modeBadge(descriptor.mode)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("routes.all_pages", fallback: "All Pages"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedRoutes: [RouteGroup: [RouteDescriptor]] {
        Dictionary(
            grouping: routes.filter(\.enabled).filter { !$0.path.contains(":") },
            by: \.group
        )
    }

    @ViewBuilder
    private func modeBadge(_ mode: RouteMode) -> some View {
        Text(mode == .native ? L10n.tr("routes.mode_native", fallback: "Native") : L10n.tr("routes.mode_web", fallback: "Web"))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mode == .native ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .clipShape(Capsule())
    }

    private func groupTitle(_ group: RouteGroup) -> String {
        switch group {
        case .home: return L10n.tr("routes.group.home", fallback: "Home")
        case .search: return L10n.tr("routes.group.search", fallback: "Search")
        case .app: return L10n.tr("routes.group.app", fallback: "App")
        case .charts: return L10n.tr("routes.group.charts", fallback: "Charts")
        case .sales: return L10n.tr("routes.group.sales", fallback: "Sales")
        case .calendar: return L10n.tr("routes.group.calendar", fallback: "Calendar")
        case .rankings: return L10n.tr("routes.group.rankings", fallback: "Rankings")
        case .utility: return L10n.tr("routes.group.utility", fallback: "Utility")
        case .entities: return L10n.tr("routes.group.entities", fallback: "Entities")
        case .unknown: return L10n.tr("routes.group.other", fallback: "Other")
        }
    }
}
