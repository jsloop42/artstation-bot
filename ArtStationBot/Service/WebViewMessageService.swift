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
        case "sign-in":
            self.delegate?.setIsSignedIn(result.status ?? false)
        case "is-signed-in?":
            let isSignedIn = result.value as? Bool ?? false
            self.delegate?.setIsSignedIn(isSignedIn)
        case "send-message":
            self.delegate?.messageSendACK(result.status ?? false)
        default:
            self.log.debug(result)
            break
        }
    }
}
