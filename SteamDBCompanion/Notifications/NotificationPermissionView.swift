import SwiftUI

public struct NotificationPermissionView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = NotificationRegistrationService.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                    .neonGlow(color: LiquidGlassTheme.Colors.neonPrimary)
                
                VStack(spacing: 16) {
                    Text("Stay Updated")
                        .font(.largeTitle.bold())
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                    
                    Text("Get notified when games on your wishlist go on sale or have significant updates.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    GlassButton("Enable Notifications", icon: "bell.fill", style: .primary) {
                        Task {
                            let _ = try? await service.requestAuthorization()
                            dismiss()
                        }
                    }
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

#Preview {
    NotificationPermissionView()
}
