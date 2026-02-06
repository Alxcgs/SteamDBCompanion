import SwiftUI
import WebKit
import Combine

@MainActor
private final class EmbeddedWebState: ObservableObject {
    @Published var canGoBack = false
    @Published var estimatedProgress = 0.0
    @Published var isLoading = false

    weak var webView: WKWebView?

    func goBackOrDismiss(_ dismiss: DismissAction) {
        guard let webView else {
            dismiss()
            return
        }

        if webView.canGoBack {
            webView.goBack()
        } else {
            dismiss()
        }
    }
}

private struct EmbeddedWebView: UIViewRepresentable {
    let initialURL: URL
    @ObservedObject var state: EmbeddedWebState

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.bind(webView)
        state.webView = webView

        let request = URLRequest(url: initialURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        state.webView = webView
        if webView.url == nil {
            let request = URLRequest(url: initialURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
            webView.load(request)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.unbind()
        uiView.navigationDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var state: EmbeddedWebState?
        private var canGoBackObservation: NSKeyValueObservation?
        private var progressObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?

        init(state: EmbeddedWebState) {
            self.state = state
        }

        func bind(_ webView: WKWebView) {
            canGoBackObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    state?.canGoBack = view.canGoBack
                }
            }

            progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    state?.estimatedProgress = view.estimatedProgress
                }
            }

            loadingObservation = webView.observe(\.isLoading, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    state?.isLoading = view.isLoading
                }
            }
        }

        func unbind() {
            canGoBackObservation = nil
            progressObservation = nil
            loadingObservation = nil
        }
    }
}

public struct WebFallbackShellView: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var webState = EmbeddedWebState()

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

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()

            EmbeddedWebView(initialURL: url, state: webState)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        webState.goBackOrDismiss(dismiss)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.black.opacity(0.15))

                if webState.isLoading {
                    ProgressView(value: max(webState.estimatedProgress, 0.05))
                        .tint(LiquidGlassTheme.Colors.neonPrimary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
