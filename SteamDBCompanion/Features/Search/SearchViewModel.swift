import Foundation
import Combine

@MainActor
public class SearchViewModel: ObservableObject {
    
    @Published public var query: String = ""
    @Published public var results: [SteamApp] = []
    @Published public var isSearching: Bool = false
    @Published public var errorMessage: String?
    
    private let dataSource: SteamDBDataSource
    private var searchTask: Task<Void, Never>?
    
    public init(dataSource: SteamDBDataSource = MockSteamDBDataSource()) {
        self.dataSource = dataSource
    }
    
    public func search() {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            results = []
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
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
}
