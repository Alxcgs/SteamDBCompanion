import Foundation

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
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                if Date().timeIntervalSince(modificationDate) > expiration {
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
            
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
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
