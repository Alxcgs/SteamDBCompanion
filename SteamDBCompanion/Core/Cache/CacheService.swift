import Foundation

public struct CacheLookup<T> {
    public let value: T
    public let age: TimeInterval
    public let isExpired: Bool
}

public actor CacheService {
    
    public static let shared = CacheService()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("SteamDBDataCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    public func save<T: Encodable>(_ object: T, for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: fileURL)
        } catch {
            print("Cache save failed: \(error)")
        }
    }
    
    public func load<T: Decodable>(key: String, type: T.Type, expiration: TimeInterval = 3600) -> T? {
        guard let lookup = loadWithMetadata(key: key, type: type, expiration: expiration) else {
            return nil
        }

        guard !lookup.isExpired else { return nil }
        return lookup.value
    }

    public func loadAllowExpired<T: Decodable>(key: String, type: T.Type, expiration: TimeInterval = 3600) -> CacheLookup<T>? {
        loadWithMetadata(key: key, type: type, expiration: expiration)
    }

    public func loadWithMetadata<T: Decodable>(key: String, type: T.Type, expiration: TimeInterval = 3600) -> CacheLookup<T>? {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let age: TimeInterval
            if let modificationDate = attributes[.modificationDate] as? Date {
                age = Date().timeIntervalSince(modificationDate)
            } else {
                age = 0
            }
            
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return CacheLookup(value: decoded, age: age, isExpired: age > expiration)
        } catch {
            print("Cache load failed: \(error)")
            return nil
        }
    }
    
    public func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
