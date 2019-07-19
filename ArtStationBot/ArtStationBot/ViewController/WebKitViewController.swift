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
    let scriptName = "asb"
    lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        let script = "webkit.messageHandlers.\(scriptName).postMessage(document.URL)"
        let userScript = WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        contentController.add(self, name: scriptName)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        let webView = WKWebView(frame: CGRect.zero, configuration: config)
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

    func execJS() {
        let script = "webkit.messageHandlers.\(scriptName).postMessage(document.querySelector('.fixed-main-nav').classList.value.length)"
        self.webView.evaluateJavaScript(script) { _, err in
            if err != nil { self.log.error("Script execution error: \(err!)" as Any) }
        }
    }
}

extension WebKitViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == scriptName {
            self.log.debug("msg: \(message.body)")
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
