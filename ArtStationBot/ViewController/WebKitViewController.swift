//
//  WebKitViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Foundation
import WebKit
import DLLogger

// MARK: - State

class WebViewState {
    private var urlStack: [String] = [Const.seedURL()]
    private var navStack: [NavigationPage] = [.home]
    private var isSignedIn = false

    // MARK: - Get

    func getCurrentURL() -> String {
        return self.urlStack.last ?? Const.seedURL()
    }

    func getCurrentPage() -> NavigationPage {
        return navStack.last ?? .home
    }

    func getIsSignedIn() -> Bool {
        return self.isSignedIn
    }

    // MARK: - Set

    func addCurrentURL(_ url: String) {
        self.urlStack.append(url)
    }

    func addCurrentPage(_ page: NavigationPage) {
        self.navStack.append(page)
    }

    func setIsSignedIn(_ flag: Bool) {
        self.isSignedIn = flag
    }

    // MARK: - Remove

    func removeCurrentURL() {
        if self.urlStack.count > 1 {
            _ = self.urlStack.popLast()
        }
    }

    func removeCurrentPage() {
        if self.navStack.count > 1 {
            _ = self.navStack.popLast()
        }
    }
}

// MARK: - WebKit view controller

class WebKitViewController: NSViewController {
    private let log = Logger()
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect.zero, configuration: initWebKitConfig())
        return webView
    }()
    private lazy var msgService: WebViewMessageService = {
        let s = WebViewMessageService()
        s.delegate = self
        return s
    }()
    var state: WebViewState = WebViewState()
    var shouldSignIn = false
    private var queue: [(UserMessageKey, UserMessageState)] = []

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        self.view = NSView()
        //self.log.debug("webkit load view")
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.customUserAgent = Utils.getRandomUserAgent()
        self.view.addSubview(self.webView)
        // self.resetWebView()
    }

    override func viewDidLoad() {
        self.initEvents()
        self.initData()
    }

    func setShouldSignIn(_ flag: Bool) {
        self.shouldSignIn = flag
    }

    /// Resets the webview's cookies and cache
    func resetWebView() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{})
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
        contentController.add(self, name: self.msgService.getHandlerName())
        return contentController
    }

    func getUserScript() -> String? {
        let url = Bundle(for: type(of: self)).url(forResource: "artstationbot", withExtension: "js", subdirectory: nil)
        guard let theUrl = url else { return nil }
        return try? String(contentsOf: theUrl, encoding: .utf8)
    }

    func initEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(sendMessage(_:)), name: NSNotification.Name(rawValue: ASNotification.sendMessage),
                                               object: nil)
    }

    func initData() {
        if let url = URL(string: Const.seedURL()) {
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

    // MARK: - Notification handlers

    @objc func sendMessage(_ notif: Notification) {
        if let info = notif.userInfo, let key = info["key"] as? UserMessageKey, let state = info["state"] as? UserMessageState {
            /*
              1. Check sign-in, if not, sign-in.
              2. Load the user's profile page
              3. Invoke send message button click,
              4. Fill the fields and invoke send
              5. Notifiy ack
            */
            // TODO: send msg
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: ASNotification.sendMessageACK), object: self,
                                            userInfo: ["status": true, "key": key, "state": state])
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ASNotification.sendMessageACK), object: self, userInfo: ["status": false])
    }
}

/// Message service delegate methods
extension WebKitViewController: WebViewMessageServiceDelegate {
    func setIsSignedIn(_ flag: Bool) {
        self.log.debug("is-signed-in?: \(flag)")
        self.state.setIsSignedIn(flag)
        // can begin sending messages
    }
}

extension WebKitViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.msgService.process(message: message)
    }
}

extension WebKitViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //self.log.debug("webview is loading")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        //self.log.debug("webview did fail to provision")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //self.log.debug("webview did finish")
        switch self.state.getCurrentPage() {
        case .home:
            if !self.state.getIsSignedIn() && self.shouldSignIn { self.signIn() }
        case .signIn:
            self.state.addCurrentPage(.home)
            self.isSignedIn()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        //self.log.debug("webview did fail")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //self.log.debug("webview did commit")
    }
}

/// Artstation website interaction methods
extension WebKitViewController {
    func signIn() {
        self.shouldSignIn = true
        self.state.addCurrentPage(.signIn)
        //self.execJS("asb.signIn('email-address', 'password')")
    }

    func isSignedIn() {
        self.execJS("asb.isSignedIn()")
    }
}

enum NavigationPage {
    case home
    case signIn
}
