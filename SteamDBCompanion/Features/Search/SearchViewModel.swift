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
    @Published public var lastSearchedQuery: String = ""

    public let minimumQueryLength = 2
    
    private let dataSource: SteamDBDataSource
    private var searchTask: Task<Void, Never>?
    
    public init(dataSource: SteamDBDataSource? = nil) {
        self.dataSource = dataSource ?? MockSteamDBDataSource()
    }
    
    public func search() {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            errorMessage = nil
            isSearching = false
            lastSearchedQuery = ""
            return
        }

        guard trimmedQuery.count >= minimumQueryLength else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }
        
        isSearching = true
        errorMessage = nil
        let requestQuery = trimmedQuery
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            if Task.isCancelled { return }
            
            do {
                let apps = try await dataSource.searchApps(query: requestQuery)
                if !Task.isCancelled {
                    guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == requestQuery else {
                        return
                    }
                    self.results = apps
                    self.lastSearchedQuery = requestQuery
                    self.errorMessage = nil
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == requestQuery else {
                        return
                    }
                    self.errorMessage = "\(L10n.tr("search.error", fallback: "Search failed")): \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }

    deinit {
        searchTask?.cancel()
    }
}
