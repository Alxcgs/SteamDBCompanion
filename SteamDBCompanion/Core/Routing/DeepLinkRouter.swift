import Foundation
import Combine

@MainActor
public final class DeepLinkRouter: ObservableObject {
    @Published public var presentedPath: String?

    public init() {}

    public func handle(url: URL) {
        guard let host = url.host?.lowercased() else { return }
        guard host == "steamdb.info" || host == "www.steamdb.info" else { return }

        let path = url.path.isEmpty ? "/" : url.path
        presentedPath = path
    }

    public func dismiss() {
        presentedPath = nil
    }
}
