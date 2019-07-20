//
//  MessageService.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import WebKit
import DLLogger

/// A class which handles messaging between the webview and the app.
class MessageService {
    static let shared = MessageService()
    private let log = Logger()
    private let msgHandlerName = "asb"

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
        default:
            self.log.debug(result)
            break
        }
    }
}


