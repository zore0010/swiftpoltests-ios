import SwiftUI
import UIKit
import WebKit

/// One quiz in a WKWebView. Connects the page to ProgressStore through the overlay script.
struct TestWebView: UIViewRepresentable {
    let test: TestDefinition
    let webRoot: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(test: test)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: OverlayScript.messageName)
        controller.addUserScript(WKUserScript(
            source: OverlayScript.source(for: test.id),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.setURLSchemeHandler(
            TestSchemeHandler(webRoot: webRoot, knownTests: TestCatalog.ids),
            forURLScheme: TestRouting.scheme
        )
        // The default data store keeps each test's localStorage between launches.
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.webView = webView
        webView.load(URLRequest(url: TestRouting.startURL(for: test)))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: OverlayScript.messageName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let test: TestDefinition
        weak var webView: WKWebView?
        private static let externalSchemes: Set<String> = ["http", "https", "mailto"]

        init(test: TestDefinition) {
            self.test = test
            super.init()
        }

        // Messages from the overlay script on the quiz pages.
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            switch type {
            case "load":
                // Hand the saved progress (or null) back to the quiz page.
                let saved = ProgressStore.loadProgress(test.id) ?? "null"
                webView?.evaluateJavaScript("window.wkwvRestore(" + saved + ");", completionHandler: nil)
            case "save":
                if let payload = body["payload"] as? String {
                    try? ProgressStore.saveProgress(payload, for: test.id)
                }
            case "complete":
                if let payload = body["payload"] as? String {
                    try? ProgressStore.recordCompletion(payload, for: test.id)
                }
            default:
                break
            }
        }

        // Links to other sites leave the app through Safari.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if url.scheme == TestRouting.scheme {
                decisionHandler(.allow)
                return
            }

            if let scheme = url.scheme, Self.externalSchemes.contains(scheme) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }

        // Covers window.open() and target="_blank".
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url,
               let scheme = url.scheme,
               Self.externalSchemes.contains(scheme) {
                UIApplication.shared.open(url)
            }
            return nil
        }
    }
}
