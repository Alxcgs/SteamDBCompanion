import XCTest
@testable import SteamDBCompanion

@MainActor
final class NotificationRegistrationServiceTests: XCTestCase {
    func testRegisterDeviceTokenStoresHexTokenAndCallsClient() async throws {
        let client = RecordingDeviceTokenRegistrationClient()
        let service = NotificationRegistrationService(
            registrationClient: client,
            checksAuthorizationOnInit: false
        )

        service.registerDeviceToken(Data([0x0a, 0x1b, 0xff]))

        try await waitFor {
            await client.registeredTokens == ["0a1bff"]
        }
        XCTAssertEqual(service.deviceToken, "0a1bff")
    }

    private func waitFor(
        timeout: TimeInterval = 1,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for async condition.")
    }
}

private actor RecordingDeviceTokenRegistrationClient: DeviceTokenRegistrationClient {
    private(set) var registeredTokens: [String] = []

    func registerDeviceToken(_ token: String) async throws {
        registeredTokens.append(token)
    }
}
