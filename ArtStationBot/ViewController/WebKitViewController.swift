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

@objc
@objcMembers
class WebViewState: NSObject {
    private var urlStack: [String] = [Const.seedURL()]
    private var navStack: [NavigationPage] = [.home]
    private var isSignedIn = false
    var username = ""
    var password = ""
    var key: UserMessageKey?
    var messageState: UserMessageState?
    var callback: ((_ status: Bool) -> Void)?

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

@objc
@objcMembers
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
    var _shouldSignIn = false
    private var queue: [(UserMessageKey, UserMessageState)] = []
    var seedURL = Const.seedURL()
    var invokeSendMessage = false

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
        self._shouldSignIn = flag
    }

    func setCredentials(_ username: String, password: String) {
        self.state.username = username
        self.state.password = password
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

    }

    func initData() {
        if let url = URL(string: self.seedURL) {
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

    func execJS(_ script: String) {
        self.webView.evaluateJavaScript(script) { _, err in
            if err != nil { self.log.error("Script execution error: \(err!)" as Any) }
        }
    }

    /// Executes the given script in the web view
    func execJS(_ dict: [String: Any], fnName: String) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted), let jsonString = String(data: jsonData, encoding: .utf8) {
            self.webView.evaluateJavaScript("\(fnName)(\(jsonString))") { res, err in
                if err != nil { self.log.error("Script execution error: \(err!)" as Any) }
            }
        }
    }

    // MARK: - Send message

    func sendMessage(_ key: UserMessageKey, state: UserMessageState, callback: @escaping (_ status: Bool) -> Void) {
        /*
          1. Check sign-in, if not, sign-in.
          2. Load the user's profile page
          3. Invoke send message button click,
          4. Fill the fields and invoke send
          5. Notifiy ack
        */
        self.state.callback = callback
        //let profileURL = state.user.artstationProfileURL
        let profileURL = "https://artstation.com/foobar42" // TODO: remove test
        if let url = URL(string: profileURL) {
            self.state.addCurrentPage(.profile)
            self.state.key = key
            self.state.messageState = state
            self.webView.load(URLRequest(url: url))
        }
    }

    func profileURLDidLoad() {
        if let msgState = self.state.messageState {
            if !self.state.getIsSignedIn() {
                self.log.debug("Not signed in. Signing in..")
                self.invokeSendMessage = true
                self.signIn()
            } else {
                self.invokeSendMessage = false
                self.log.debug("Signed in. Sending message.")
                var msg = msgState.skill.interpolatedMessage
                msg = "Hi, How are you doing? Bye"  // TODO: remove test
                self.execJS(["msg": msg], fnName: "asb.sendMessage")
            }
        }
    }
}

/// Message service delegate methods
extension WebKitViewController: WebViewMessageServiceDelegate {
    func setIsSignedIn(_ flag: Bool) {
        self.log.debug("is-signed-in?: \(flag)")
        self.state.setIsSignedIn(flag)
        // can begin sending messages
        if self.invokeSendMessage {
            self.profileURLDidLoad()
        }
    }

    func messageSendACK(_ flag: Bool) {
        self.log.debug("message send status: \(flag)")
        if let cb = self.state.callback {
            cb(flag)
        }
    }
}

extension WebKitViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.msgService.process(message: message)
    }
}

extension WebKitViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.log.debug("webview is loading")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.log.debug("webview did fail to provision")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.log.debug("webview did finish")
        switch self.state.getCurrentPage() {
        case .home:
            if !self.state.getIsSignedIn() && self._shouldSignIn { self.signIn() }
        case .signIn:
            self.state.addCurrentPage(.home)
            self.isSignedIn()
        case .profile:
            self.profileURLDidLoad()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.log.debug("webview did fail")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.log.debug("webview did commit")
    }
}

/// Artstation website interaction methods
extension WebKitViewController {
    func signIn() {
        self._shouldSignIn = true
        self.state.addCurrentPage(.signIn)
        if !self.state.username.isEmpty && !self.state.password.isEmpty {
            self.execJS(["username": self.state.username, "password": self.state.password], fnName: "asb.signIn");
        } else {
            self.log.error("Artstation sender credentials cannot be empty")
        }
    }

    func isSignedIn() {
        self.execJS("asb.isSignedIn()")
    }
}

enum NavigationPage {
    case home
    case signIn
    case profile
}
