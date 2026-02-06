import SwiftUI

public enum GlassButtonStyle {
    case primary
    case secondary
    case destructive
}

/// A button styled with the Liquid Glass system.
public struct GlassButton: View {
    
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var icon: String?
    var style: GlassButtonStyle
    var action: () -> Void
    
    public init(_ title: String, icon: String? = nil, style: GlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary: return LiquidGlassTheme.Colors.neonPrimary.opacity(0.2)
        case .secondary: return colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.1)
        case .destructive: return LiquidGlassTheme.Colors.neonError.opacity(0.2)
        }
    }
    
    var foregroundColor: Color {
        switch style {
        case .primary: return LiquidGlassTheme.Colors.neonPrimary
        case .secondary: return colorScheme == .dark ? .white : .primary
        case .destructive: return LiquidGlassTheme.Colors.neonError
        }
    }
    
    public var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                    .strokeBorder(foregroundColor.opacity(0.5), lineWidth: 1)
            )
            .foregroundStyle(foregroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()) // To avoid default list row highlights if used in lists
        .shadow(color: foregroundColor.opacity(0.3), radius: 5, x: 0, y: 0)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            GlassButton("Primary Action", icon: "star.fill", style: .primary) {}
            GlassButton("Secondary Action", icon: "info.circle", style: .secondary) {}
            GlassButton("Delete", icon: "trash", style: .destructive) {}
        }
        .padding()
    }
}
