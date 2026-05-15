import Foundation
import UserNotifications
import UIKit
import Combine
import OSLog

@MainActor
public class NotificationRegistrationService: ObservableObject {
    private static let logger = Logger(subsystem: "com.steamdb.SteamDBCompanion", category: "NotificationRegistration")
    
    @Published public var isAuthorized: Bool = false
    @Published public var deviceToken: String?
    
    public static let shared = NotificationRegistrationService()

    private let registrationClient: any DeviceTokenRegistrationClient
    
    public init(
        registrationClient: any DeviceTokenRegistrationClient = NoOpDeviceTokenRegistrationClient(),
        checksAuthorizationOnInit: Bool = true
    ) {
        self.registrationClient = registrationClient
        if checksAuthorizationOnInit {
            checkAuthorizationStatus()
        }
    }
    
    public func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    public func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
            self.isAuthorized = true
        }
        
        return granted
    }
    
    public func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token

        Task {
            do {
                try await registrationClient.registerDeviceToken(token)
                Self.logger.debug("Device token registration completed.")
            } catch {
                Self.logger.error("Device token registration failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    public func didFailToRegister(error: Error) {
        Self.logger.error("Failed to register for notifications: \(error.localizedDescription, privacy: .public)")
    }
}
