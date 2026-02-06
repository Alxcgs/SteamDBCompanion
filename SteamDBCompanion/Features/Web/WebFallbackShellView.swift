import SwiftUI
import SafariServices

private struct SteamDBSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // SFSafariViewController manages navigation state internally.
    }
}

public struct WebFallbackShellView: View {
    let url: URL
    let title: String
    @Environment(\.openURL) private var openURL

    public init(path: String, title: String) {
        let normalizedPath: String
        if path.isEmpty {
            normalizedPath = "/"
        } else if path.hasPrefix("/") {
            normalizedPath = path
        } else {
            normalizedPath = "/\(path)"
        }
        self.url = URL(string: "https://steamdb.info\(normalizedPath)")!
        self.title = title
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            SteamDBSafariView(url: url)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Text("Web mode: \(title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                GlassButton("Open in Safari app", icon: "safari", style: .secondary) {
                    openURL(url)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
}
