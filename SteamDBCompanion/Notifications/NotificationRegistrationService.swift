import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
public class NotificationRegistrationService: ObservableObject {
    
    @Published public var isAuthorized: Bool = false
    @Published public var deviceToken: String?
    
    public static let shared = NotificationRegistrationService()
    
    private init() {
        checkAuthorizationStatus()
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
        print("APNs Token: \(token)")
        // TODO: Send to backend
    }
    
    public func didFailToRegister(error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
}
