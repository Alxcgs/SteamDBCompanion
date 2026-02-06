import SwiftUI

public struct SearchView: View {
    
    @StateObject private var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    
    public init(dataSource: SteamDBDataSource) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(dataSource: dataSource))
    }
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search apps, packages...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                    
                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding()
                
                // Results
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isSearching {
                            ProgressView()
                                .padding(.top, 50)
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonError)
                                Text(errorMessage)
                                    .font(.callout)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 50)
                        } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                            Text("No results found")
                                .foregroundStyle(.secondary)
                                .padding(.top, 50)
                        } else if !viewModel.results.isEmpty {
                            if DeviceInfo.isIPad {
                                // iPad: Grid layout
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                                    spacing: 16
                                ) {
                                    ForEach(viewModel.results) { app in
                                        NavigationLink(value: app) {
                                            SearchResultRow(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                // iPhone: List layout
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.results) { app in
                                        NavigationLink(value: app) {
                                            SearchResultRow(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = true
        }
    }
}

struct SearchResultRow: View {
    let app: SteamApp
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack {
                if let imageURL = app.headerImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    Image(systemName: "gamecontroller")
                                        .foregroundStyle(.white.opacity(0.5))
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "gamecontroller")
                                .foregroundStyle(.white.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                    
                    HStack {
                        Text(app.type.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        
                        if let price = app.price {
                            Text(price.formatted)
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
        SearchView(dataSource: MockSteamDBDataSource())
    }
}
