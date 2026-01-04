import SwiftUI
import WebKit

public struct SteamDBWebView: View {
    private let url: URL

    public init(url: URL = URL(string: "https://steamdb.info")!) {
        self.url = url
    }

    public var body: some View {
        WebView(url: url)
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("SteamDB Web")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

#Preview {
    NavigationStack {
        SteamDBWebView()
    }
}
