//
//  WebKitViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import WebKit
import DLLogger

class WebKitViewController: NSViewController {
    private let log = Logger()
    let msgHandlerName = "asb"
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect.zero, configuration: initWebKitConfig())
        webView.navigationDelegate = self
        return webView
    }()

    override func loadView() {
        self.view = NSView()
        self.log.debug("webkit load view")
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)
    }

    override func viewDidLoad() {
        self.initEvents()
        self.initData()
    }

    // MARK: - Init

    func initWebKitConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.userContentController = initUserContentController()
        return config
    }

    func initUserContentController() -> WKUserContentController {
        let contentController = WKUserContentController()
        let script = getUserScript() ?? ""
        let userScript = WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        contentController.add(self, name: msgHandlerName)
        return contentController
    }

    func getUserScript() -> String? {
        let url = Bundle(for: type(of: self)).url(forResource: "artstationbot", withExtension: "js", subdirectory: nil)
        guard let theUrl = url else { return nil }
        return try? String(contentsOf: theUrl, encoding: .utf8)
    }

    func initEvents() {
        self.webView.navigationDelegate = self
    }

    func initData() {
        if let url = URL(string: Const.seedURL) {
            self.webView.load(URLRequest(url: url))
        }
    }

    func getAllCookies() {
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                print("\(cookie.name) is set to \(cookie.value)")
            }
        }
    }

    /// Executes the given script in the web view
    func execJS(_ script: String? = nil) {
        let aScript: String = { if let s = script { return s }; return "asb.init(); asb.getCount()" }()
        self.webView.evaluateJavaScript(aScript) { _, err in
            if err != nil { self.log.error("Script execution error: \(err!)" as Any) }
        }
    }
}

extension WebKitViewController: WKScriptMessageHandler {
    /// Delegate method which recieves any message send from user script.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let result = ScriptResult(message.body)
        switch result.id {
        case "document-url":
            self.log.debug(result.value as Any)
        case "greet":
            self.log.debug(result.msg as Any)
        case "main-nav-len":
            self.log.debug(result.value as Any)
        default:
            self.log.debug(result)
            break
        }
    }
}

extension WebKitViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.log.debug("site is loading")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.log.debug("site did fail to provision")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.log.debug("did finish")
        self.execJS()
    }
}
