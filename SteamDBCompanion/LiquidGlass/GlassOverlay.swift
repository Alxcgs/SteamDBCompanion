import SwiftUI

/// A modal overlay that slides up or fades in with a glass background.
public struct GlassOverlay<Content: View>: View {
    
    @Binding var isPresented: Bool
    var content: Content
    
    public init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            if isPresented {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                
                // Glass Content
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Drag handle
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        
                        content
                    }
                    .padding()
                    .background(GlassBackgroundView(material: .regularMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .glassBorder()
                    .shadow(radius: 20)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

#Preview {
    GlassOverlay(isPresented: .constant(true)) {
        Text("This is a glass overlay")
            .padding()
        GlassButton("Close") { }
    }
}
