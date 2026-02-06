import SwiftUI
import WebKit
import Combine

@MainActor
final class WebFallbackState: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = true

    weak var webView: WKWebView?

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }
}

struct SteamDBWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var state: WebFallbackState

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        state.webView = webView
        context.coordinator.loadIfNeeded(webView, targetURL: url)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.loadIfNeeded(webView, targetURL: url)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let state: WebFallbackState
        private var lastLoadedURL: URL?

        init(state: WebFallbackState) {
            self.state = state
        }

        func loadIfNeeded(_ webView: WKWebView, targetURL: URL) {
            if lastLoadedURL == targetURL {
                return
            }
            lastLoadedURL = targetURL
            var request = URLRequest(url: targetURL)
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
                forHTTPHeaderField: "User-Agent"
            )
            webView.load(request)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.isLoading = true
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.isLoading = false
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.isLoading = false
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
        }
    }
}

public struct WebFallbackShellView: View {
    let url: URL
    let title: String
    @StateObject private var state = WebFallbackState()
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

            SteamDBWebView(url: url, state: state)
                .ignoresSafeArea()

            if state.isLoading {
                ProgressView("Loading \(title)...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    state.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .disabled(!state.canGoBack)

                Button {
                    state.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .disabled(!state.canGoForward)

                Spacer()

                Button {
                    state.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 32, height: 32)
                }

                Button {
                    openURL(url)
                } label: {
                    Image(systemName: "safari")
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
}
