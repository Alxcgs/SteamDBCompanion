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
                        ForEach(entries.filter(\.enabled)) { descriptor in
                            if descriptor.path.contains(":") {
                                NavigationLink {
                                    ParameterizedRouteInputView(descriptor: descriptor, dataSource: dataSource)
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
                            } else {
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
        }
        .navigationTitle("All Pages")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedRoutes: [RouteGroup: [RouteDescriptor]] {
        Dictionary(grouping: routes, by: \.group)
    }

    @ViewBuilder
    private func modeBadge(_ mode: RouteMode) -> some View {
        Text(mode == .native ? "Native" : "Web")
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mode == .native ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .clipShape(Capsule())
    }

    private func groupTitle(_ group: RouteGroup) -> String {
        switch group {
        case .home: return "Home"
        case .search: return "Search"
        case .app: return "App"
        case .charts: return "Charts"
        case .sales: return "Sales"
        case .calendar: return "Calendar"
        case .rankings: return "Rankings"
        case .utility: return "Utility"
        case .entities: return "Entities"
        case .unknown: return "Other"
        }
    }
}

private struct ParameterizedRouteInputView: View {
    let descriptor: RouteDescriptor
    let dataSource: SteamDBDataSource

    @State private var parameterValue = ""
    @State private var resolvedPath: String?

    var body: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Path template")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(descriptor.path)
                        .font(.headline)
                    TextField(parameterPlaceholder, text: $parameterValue)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal)

            GlassButton("Open", style: .primary) {
                resolvedPath = buildPath()
            }
            .padding(.horizontal)

            Spacer()

            NavigationLink(
                destination: Group {
                    if let resolvedPath {
                        RouteHostView(path: resolvedPath, dataSource: dataSource)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { resolvedPath != nil },
                    set: { isActive in
                        if !isActive {
                            resolvedPath = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
        .padding(.top, 16)
        .navigationTitle(descriptor.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var parameterPlaceholder: String {
        let firstParameter = descriptor.path.split(separator: "/").first { $0.hasPrefix(":") }.map(String.init)
        if let firstParameter {
            return firstParameter.replacingOccurrences(of: ":", with: "")
        }
        return "id"
    }

    private func buildPath() -> String {
        let value = parameterValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackValue = value.isEmpty ? "730" : value
        let components = descriptor.path
            .split(separator: "/")
            .map { segment -> String in
                segment.hasPrefix(":") ? fallbackValue : String(segment)
            }
        return "/\(components.joined(separator: "/"))"
    }
}
