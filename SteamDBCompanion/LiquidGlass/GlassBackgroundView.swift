import SwiftUI

/// A reusable background view that implements the "Liquid Glass" aesthetic.
/// It uses SwiftUI Materials combined with custom gradients and blurs.
public struct GlassBackgroundView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    var material: Material
    var opacity: Double
    
    public init(material: Material = .ultraThinMaterial, opacity: Double = 1.0) {
        self.material = material
        self.opacity = opacity
    }
    
    public var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color.black
                    .opacity(opacity)
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.04, green: 0.04, blue: 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.9 * opacity)
            } else {
                Rectangle()
                    .fill(material)
                    .opacity(opacity)
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
