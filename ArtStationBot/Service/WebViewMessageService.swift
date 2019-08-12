//
//  WebViewMessageService.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//

import Foundation
import WebKit
import DLLogger

protocol WebViewMessageServiceDelegate: class {
    func setIsSignedIn(_ flag: Bool)
    func messageSendACK(_ flag: Bool)
}

/// A class which handles messaging between the webview and the app.
class WebViewMessageService {
    private let log = Logger()
    private let msgHandlerName = "asb"
    weak var delegate: WebViewMessageServiceDelegate?

    func getHandlerName() -> String {
        return self.msgHandlerName
    }

    func process(message: WKScriptMessage) {
        let result = ScriptResult(message.body)
        switch result.id {
        case "document-url":
            self.log.debug(result.value as Any)
        case "greet":
            self.log.debug(result.msg as Any)
        case "main-nav-len":
            self.log.debug(result.value as Any)
        case "sign-in":
            self.log.debug(result.msg as Any)  // error message
            self.delegate?.setIsSignedIn(result.status ?? false)
        case "is-signed-in?":
            let isSignedIn = result.value as? Bool ?? false
            self.log.debug(isSignedIn)
            self.delegate?.setIsSignedIn(isSignedIn)
        case "load-profile":
            let isProfileLoaded = result.value as? Bool ?? false
            self.log.debug("profile loaded: \(isProfileLoaded)")
        case "send-message":
            self.log.debug("msg: \(result.msg ?? "")")
            self.delegate?.messageSendACK(result.status ?? false)
        default:
            self.log.debug(result)
            break
        }
    }
}
