import Foundation
import OSLog

public protocol DeviceTokenRegistrationClient: Sendable {
    func registerDeviceToken(_ token: String) async throws
}

public struct NoOpDeviceTokenRegistrationClient: DeviceTokenRegistrationClient {
    private static let logger = Logger(subsystem: "com.steamdb.SteamDBCompanion", category: "DeviceTokenRegistration")

    public init() {}

    public func registerDeviceToken(_ token: String) async throws {
        Self.logger.debug("Device token registration skipped because no backend client is configured.")
    }
}
