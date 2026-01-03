import SwiftUI

/// A shimmer effect for loading states
public struct ShimmerView: View {
    
    @State private var phase: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 400
            }
        }
    }
}

/// Skeleton loading card for app items
public struct SkeletonAppCard: View {
    
    public init() {}
    
    public var body: some View {
        GlassCard(padding: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(ShimmerView())
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 150, height: 16)
                        .overlay(ShimmerView())
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 12)
                        .overlay(ShimmerView())
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            SkeletonAppCard()
            SkeletonAppCard()
        }
        .padding()
    }
}
