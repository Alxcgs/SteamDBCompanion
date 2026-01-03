import SwiftUI

/// Defines the core design tokens for the Liquid Glass system.
public struct LiquidGlassTheme {
    
    // MARK: - Colors
    
    public struct Colors {
        /// A subtle, translucent background for glass surfaces.
        public static let glassBackground = Color.white.opacity(0.1)
        
        /// A slightly more opaque background for elevated glass surfaces.
        public static let glassElevated = Color.white.opacity(0.15)
        
        /// A border color for glass edges, simulating light catching the edge.
        public static let glassBorder = LinearGradient(
            colors: [
                Color.white.opacity(0.5),
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Primary neon accent color (SteamDB Blue/Cyan).
        public static let neonPrimary = Color(red: 0.0, green: 0.8, blue: 1.0)
        
        /// Secondary neon accent color (SteamDB Pink/Purple/Red).
        public static let neonSecondary = Color(red: 1.0, green: 0.2, blue: 0.6)
        
        /// Text color optimized for glass backgrounds.
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        
        /// Success/Green neon.
        public static let neonSuccess = Color(red: 0.2, green: 1.0, blue: 0.4)
        
        /// Warning/Yellow neon.
        public static let neonWarning = Color(red: 1.0, green: 0.8, blue: 0.0)
        
        /// Error/Red neon.
        public static let neonError = Color(red: 1.0, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Spacing & Layout
    
    public struct Layout {
        public static let cornerRadius: CGFloat = 20
        public static let padding: CGFloat = 16
        public static let smallPadding: CGFloat = 8
    }
    
    // MARK: - Shadows
    
    public static func applyGlassShadow<V: View>(_ view: V) -> some View {
        view.shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a standard glass border.
    public func glassBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                .strokeBorder(LiquidGlassTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    /// Applies a neon glow effect.
    public func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
}
