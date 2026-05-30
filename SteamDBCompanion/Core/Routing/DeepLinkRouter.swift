import Foundation
import Combine

@MainActor
public final class DeepLinkRouter: ObservableObject {
    @Published public var presentedURL: URL?

    public init() {}

    public func handle(url: URL) {
        guard let host = url.host?.lowercased() else { return }
        guard host == "steamdb.info" || host == "www.steamdb.info" else { return }

        presentedURL = url
    }

    public func dismiss() {
        presentedURL = nil
    }
}
