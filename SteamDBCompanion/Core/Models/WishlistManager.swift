import Foundation
import Combine

@MainActor
public class WishlistManager: ObservableObject {
    
    @Published public var wishlist: Set<Int> = []
    
    private let saveKey = "user_wishlist"
    
    public init() {
        load()
    }
    
    public func toggleWishlist(appID: Int) {
        if wishlist.contains(appID) {
            wishlist.remove(appID)
        } else {
            wishlist.insert(appID)
        }
        save()
    }
    
    public func isWishlisted(appID: Int) -> Bool {
        wishlist.contains(appID)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(wishlist) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.wishlist = saved
        }
    }
}
