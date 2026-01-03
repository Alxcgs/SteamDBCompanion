import SwiftUI

/// A reusable background view that implements the "Liquid Glass" aesthetic.
/// It uses SwiftUI Materials combined with custom gradients and blurs.
public struct GlassBackgroundView: View {
    
    var material: Material
    var opacity: Double
    
    public init(material: Material = .ultraThinMaterial, opacity: Double = 1.0) {
        self.material = material
        self.opacity = opacity
    }
    
    public var body: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(material)
                .opacity(opacity)
            
            // Subtle noise or gradient overlay can be added here for texture
            LinearGradient(
                colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        Text("Hello Glass")
            .font(.largeTitle)
            .padding()
            .background(GlassBackgroundView())
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
