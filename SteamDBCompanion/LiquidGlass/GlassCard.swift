import SwiftUI

/// A container view that applies the standard glass styling:
/// Material background, rounded corners, border, and shadow.
public struct GlassCard<Content: View>: View {
    
    @Environment(\.colorScheme) private var colorScheme
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
                RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                    .fill(cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                    .strokeBorder(cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.15), radius: 15, x: 0, y: 10)
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.92)
            : Color.white.opacity(0.55)
    }

    private var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.45)
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
