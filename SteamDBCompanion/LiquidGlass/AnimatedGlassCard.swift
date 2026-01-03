import SwiftUI

/// Enhanced glass card with smooth scale animation on appear
public struct AnimatedGlassCard<Content: View>: View {
    
    var content: Content
    var padding: CGFloat
    @State private var appeared = false
    
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
            .scaleEffect(appeared ? 1.0 : 0.95)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
    }
}
