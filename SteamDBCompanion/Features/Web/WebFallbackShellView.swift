import SwiftUI
import WebKit
import Combine
import UIKit

private enum WebLoadState: Equatable {
    case loading
    case loaded
    case failed(String)
}

private enum WebViewportInsets {
    static func top() -> CGFloat {
        guard let window = keyWindow() else { return 0 }
        return window.safeAreaInsets.top
    }

    static func bottom() -> CGFloat {
        guard let window = keyWindow() else { return 0 }
        return window.safeAreaInsets.bottom
    }

    private static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}

@MainActor
private final class EmbeddedWebState: ObservableObject {
    @Published var canGoBack = false
    @Published var estimatedProgress = 0.0
    @Published var isLoading = false
    @Published var loadState: WebLoadState = .loading

    weak var webView: WKWebView?

    private var fallbackURL: URL?
    private var initialURL: URL?
    private var didAttemptFallback = false
    private var hasLoadedContent = false
    private var timeoutTask: Task<Void, Never>?

    deinit {
        timeoutTask?.cancel()
    }

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

    func configure(initialURL: URL, fallbackURL: URL?) {
        self.initialURL = initialURL
        if self.fallbackURL != fallbackURL {
            self.fallbackURL = fallbackURL
            didAttemptFallback = false
        }
    }

    func beginLoading() {
        isLoading = true
        loadState = .loading
        scheduleTimeout()
    }

    func finishLoading() {
        isLoading = false
        hasLoadedContent = true
        loadState = .loaded
        cancelTimeout()
    }

    func failLoading(reason: String) {
        isLoading = false
        cancelTimeout()
        if !hasLoadedContent {
            loadState = .failed(reason)
        }
    }

    func reloadPrimary() {
        guard let webView, let initialURL else {
            return
        }
        didAttemptFallback = false
        beginLoading()
        let request = URLRequest(url: initialURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
        webView.load(request)
    }

    @discardableResult
    func tryFallbackIfAvailable(from webView: WKWebView) -> Bool {
        guard
            !didAttemptFallback,
            let fallbackURL
        else {
            return false
        }

        didAttemptFallback = true
        beginLoading()
        let request = URLRequest(url: fallbackURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
        webView.load(request)
        return true
    }

    func resetFallbackAttempt() {
        didAttemptFallback = false
        hasLoadedContent = false
        loadState = .loading
        cancelTimeout()
    }

    private func scheduleTimeout() {
        cancelTimeout()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard let self, !Task.isCancelled else { return }
            if !self.hasLoadedContent {
                self.isLoading = false
                self.loadState = .failed(L10n.tr("web.error_timeout", fallback: "Web page load timed out."))
            }
        }
    }

    private func cancelTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}

private struct EmbeddedWebView: UIViewRepresentable {
    let initialURL: URL
    let fallbackURL: URL?
    let topContentInset: CGFloat
    let bottomContentInset: CGFloat
    let usesAutomaticInsets: Bool
    @ObservedObject var state: EmbeddedWebState

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state, topInset: topContentInset, bottomInset: bottomContentInset)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.userContentController.addUserScript(
            WKUserScript(
                source: injectedSafeAreaSetupScript(top: topContentInset, bottom: bottomContentInset),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = usesAutomaticInsets ? .automatic : .never
        applyInsets(to: webView)
        state.configure(initialURL: initialURL, fallbackURL: fallbackURL)
        state.resetFallbackAttempt()
        context.coordinator.bind(webView)
        context.coordinator.applySafeAreaInsets(to: webView, top: topContentInset, bottom: bottomContentInset)
        state.webView = webView

        state.beginLoading()
        let request = URLRequest(url: initialURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        state.webView = webView
        state.configure(initialURL: initialURL, fallbackURL: fallbackURL)
        context.coordinator.updateInsets(top: topContentInset, bottom: bottomContentInset)
        webView.scrollView.contentInsetAdjustmentBehavior = usesAutomaticInsets ? .automatic : .never
        applyInsets(to: webView)
        context.coordinator.applySafeAreaInsets(to: webView, top: topContentInset, bottom: bottomContentInset)
        if webView.url == nil {
            DispatchQueue.main.async {
                guard webView.url == nil else { return }
                state.beginLoading()
                let request = URLRequest(url: initialURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
                webView.load(request)
            }
        }
    }

    private func applyInsets(to webView: WKWebView) {
        guard !usesAutomaticInsets else {
            webView.scrollView.contentInset = .zero
            webView.scrollView.scrollIndicatorInsets = .zero
            return
        }

        let insets = UIEdgeInsets(top: topContentInset, left: 0, bottom: bottomContentInset, right: 0)
        webView.scrollView.contentInset = insets
        webView.scrollView.scrollIndicatorInsets = insets
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
        private var topInset: CGFloat
        private var bottomInset: CGFloat
        private var lastInjectedTop: CGFloat = -1
        private var lastInjectedBottom: CGFloat = -1

        init(state: EmbeddedWebState, topInset: CGFloat, bottomInset: CGFloat) {
            self.state = state
            self.topInset = topInset
            self.bottomInset = bottomInset
        }

        func bind(_ webView: WKWebView) {
            canGoBackObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    state?.canGoBack = view.canGoBack
                }
            }

            progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    guard let state else { return }
                    let progress = view.estimatedProgress
                    if abs(state.estimatedProgress - progress) > 0.02 || progress <= 0.05 || progress >= 1 {
                        state.estimatedProgress = progress
                    }
                }
            }

            loadingObservation = webView.observe(\.isLoading, options: [.initial, .new]) { [weak state] view, _ in
                DispatchQueue.main.async {
                    state?.isLoading = view.isLoading
                }
            }
        }

        func updateInsets(top: CGFloat, bottom: CGFloat) {
            topInset = top
            bottomInset = bottom
        }

        func applySafeAreaInsets(to webView: WKWebView, top: CGFloat, bottom: CGFloat) {
            let normalizedTop = round(top * 10) / 10
            let normalizedBottom = round(bottom * 10) / 10
            guard normalizedTop != lastInjectedTop || normalizedBottom != lastInjectedBottom else {
                return
            }
            lastInjectedTop = normalizedTop
            lastInjectedBottom = normalizedBottom
            let script = injectedSafeAreaUpdateScript(top: top, bottom: bottom)
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func unbind() {
            canGoBackObservation = nil
            progressObservation = nil
            loadingObservation = nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                if state?.tryFallbackIfAvailable(from: webView) == true {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state?.beginLoading()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state?.failLoading(reason: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state?.failLoading(reason: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state?.finishLoading()
            applySafeAreaInsets(to: webView, top: topInset, bottom: bottomInset)

            let script = """
            (function() {
              try {
                var title = (document.title || '').toLowerCase();
                var h1 = (document.querySelector('h1')?.textContent || '').toLowerCase();
                var subtitle = (document.querySelector('.title, .subtitle, p')?.textContent || '').toLowerCase();
                return title.includes('not found')
                  || title.includes('rate limited')
                  || h1.includes('not found')
                  || h1.includes('rate limited')
                  || subtitle.includes('rate limited on steamdb');
              } catch (_) { return false; }
            })();
            """
            webView.evaluateJavaScript(script) { [weak state] result, _ in
                guard
                    let state,
                    let shouldFallback = result as? Bool
                else {
                    return
                }

                if shouldFallback {
                    _ = state.tryFallbackIfAvailable(from: webView)
                }
            }
        }
    }
}

private func injectedSafeAreaSetupScript(top: CGFloat, bottom: CGFloat) -> String {
    let topValue = String(format: "%.1f", max(top, 0))
    let bottomValue = String(format: "%.1f", max(bottom, 0))
    return """
    (function() {
      try {
        var root = document.documentElement;
        if (!root) { return; }
        root.style.setProperty('--ios-safe-top', '\(topValue)px');
        root.style.setProperty('--ios-safe-bottom', '\(bottomValue)px');
        var styleId = 'steamdb-companion-safe-area-style';
        if (!document.getElementById(styleId)) {
          var style = document.createElement('style');
          style.id = styleId;
          style.textContent = `
            html, body {
              box-sizing: border-box !important;
              padding-top: calc(var(--ios-safe-top, 0px) + env(safe-area-inset-top, 0px)) !important;
              padding-bottom: calc(var(--ios-safe-bottom, 0px) + env(safe-area-inset-bottom, 0px)) !important;
            }
            [class*="header"], [class*="topbar"], .header, .topbar, .global_header, .responsive_header, .mobile_header,
            [style*="position: fixed"][style*="top"] {
              top: calc(var(--ios-safe-top, 0px) + env(safe-area-inset-top, 0px)) !important;
            }
            [class*="footer"], .footer, [style*="position: fixed"][style*="bottom"] {
              bottom: calc(var(--ios-safe-bottom, 0px) + env(safe-area-inset-bottom, 0px)) !important;
            }
          `;
          (document.head || root).appendChild(style);
        }
      } catch (_) {}
    })();
    """
}

private func injectedSafeAreaUpdateScript(top: CGFloat, bottom: CGFloat) -> String {
    let topValue = String(format: "%.1f", max(top, 0))
    let bottomValue = String(format: "%.1f", max(bottom, 0))
    return """
    (function() {
      try {
        var root = document.documentElement;
        if (!root) { return; }
        root.style.setProperty('--ios-safe-top', '\(topValue)px');
        root.style.setProperty('--ios-safe-bottom', '\(bottomValue)px');
      } catch (_) {}
    })();
    """
}

public struct WebFallbackShellView: View {
    let url: URL
    let title: String
    let fallbackURL: URL?
    let hidesTabBar: Bool
    let showsNavigationChrome: Bool
    let onLoadFailure: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var webState = EmbeddedWebState()
    @State private var didNotifyLoadFailure = false

    public init(
        path: String,
        title: String,
        fallbackURL: URL? = nil,
        hidesTabBar: Bool = true,
        showsNavigationChrome: Bool = true,
        onLoadFailure: (() -> Void)? = nil
    ) {
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
        self.fallbackURL = fallbackURL
        self.hidesTabBar = hidesTabBar
        self.showsNavigationChrome = showsNavigationChrome
        self.onLoadFailure = onLoadFailure
    }

    public init(
        url: URL,
        title: String,
        fallbackURL: URL? = nil,
        hidesTabBar: Bool = true,
        showsNavigationChrome: Bool = true,
        onLoadFailure: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.fallbackURL = fallbackURL
        self.hidesTabBar = hidesTabBar
        self.showsNavigationChrome = showsNavigationChrome
        self.onLoadFailure = onLoadFailure
    }

    public var body: some View {
        let safeTop = WebViewportInsets.top()
        let safeBottom = WebViewportInsets.bottom()
        let topInset = showsNavigationChrome ? 0 : max(safeTop, 16)
        let bottomInset = hidesTabBar ? max(safeBottom, 0) : max(safeBottom + 64, 72)
        let automaticInsets = showsNavigationChrome

        EmbeddedWebView(
            initialURL: url,
            fallbackURL: fallbackURL,
            topContentInset: topInset,
            bottomContentInset: bottomInset,
            usesAutomaticInsets: automaticInsets,
            state: webState
        )
            .background(Color.black.opacity(0.95))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .center) {
                if case let .failed(message) = webState.loadState {
                    VStack(spacing: 12) {
                        Text(L10n.tr("web.error_title", fallback: "Failed to open page"))
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Button(L10n.tr("common.retry", fallback: "Retry")) {
                                didNotifyLoadFailure = false
                                webState.reloadPrimary()
                            }
                            .buttonStyle(.borderedProminent)
                            Button(L10n.tr("web.open_in_safari", fallback: "Open in Safari")) {
                                openURL(url)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(20)
                }
            }
        .toolbar {
            if showsNavigationChrome {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        webState.goBackOrDismiss(dismiss)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
            }
        }
        .navigationBarBackButtonHidden(showsNavigationChrome)
        .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
        .toolbar(showsNavigationChrome ? .visible : .hidden, for: .navigationBar)
        .onChange(of: webState.loadState) { _, newValue in
            switch newValue {
            case .failed:
                if !didNotifyLoadFailure {
                    didNotifyLoadFailure = true
                    onLoadFailure?()
                }
            case .loading, .loaded:
                didNotifyLoadFailure = false
            }
        }
        .safeAreaInset(edge: .top) {
            if webState.isLoading {
                ProgressView(value: max(webState.estimatedProgress, 0.05))
                    .tint(LiquidGlassTheme.Colors.neonPrimary)
                    .progressViewStyle(.linear)
                    .frame(height: 2)
            }
        }
    }
}
