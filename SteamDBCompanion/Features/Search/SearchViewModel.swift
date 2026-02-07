import Foundation
import Combine

@MainActor
public class SearchViewModel: ObservableObject {
    
    @Published public var query: String = "" {
        didSet {
            search()
        }
    }
    @Published public var results: [SteamApp] = []
    @Published public var isSearching: Bool = false
    @Published public var errorMessage: String?
    
    private let dataSource: SteamDBDataSource
    private var searchTask: Task<Void, Never>?
    
    public init(dataSource: SteamDBDataSource? = nil) {
        self.dataSource = dataSource ?? MockSteamDBDataSource()
    }
    
    public func search() {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            if Task.isCancelled { return }
            
            do {
                let apps = try await dataSource.searchApps(query: query)
                if !Task.isCancelled {
                    self.results = apps
                    self.errorMessage = nil
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = "\(L10n.tr("search.error", fallback: "Search failed")): \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
}
