import SwiftUI

public struct ContentStatusView: View {
    public enum Kind {
        case loading
        case empty
        case error
        case info

        var symbolName: String {
            switch self {
            case .loading:
                return "hourglass"
            case .empty:
                return "tray"
            case .error:
                return "exclamationmark.triangle"
            case .info:
                return "info.circle"
            }
        }

        var tint: Color {
            switch self {
            case .loading, .info:
                return LiquidGlassTheme.Colors.neonPrimary
            case .empty:
                return .secondary
            case .error:
                return LiquidGlassTheme.Colors.neonError
            }
        }
    }

    private let kind: Kind
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        kind: Kind,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.kind = kind
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                if kind == .loading {
                    ProgressView()
                        .tint(kind.tint)
                } else {
                    Image(systemName: kind.symbolName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(kind.tint)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                if let actionTitle, let action {
                    GlassButton(actionTitle, style: .primary, action: action)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
    }
}

