import SwiftUI

/// A container view that applies the standard glass styling:
/// Material background, rounded corners, border, and shadow.
public struct GlassCard<Content: View>: View {
    
    var content: Content
    var padding: CGFloat
    
    public init(padding: CGFloat = LiquidGlassTheme.Layout.padding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                GlassBackgroundView(material: .thinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius))
            .glassBorder()
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        GlassCard {
            VStack(alignment: .leading) {
                Text("SteamDB Top Seller")
                    .font(.headline)
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                
                Text("Counter-Strike 2")
                    .font(.title.bold())
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                
                Text("$0.00")
                    .font(.subheadline)
                    .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                    .neonGlow(color: LiquidGlassTheme.Colors.neonSuccess)
            }
        }
        .padding()
    }
}
