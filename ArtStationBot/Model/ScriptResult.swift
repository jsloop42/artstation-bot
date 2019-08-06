//
//  ScriptResult.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//

import Foundation

/// Represents the result obtained from executing JavaScript in the webview.
class ScriptResult: CustomDebugStringConvertible {
    var id: String?
    var status: Bool?
    var msg: String?
    var value: Any?

    init() {}

    init(_ hm: Any) {
        if let dict = hm as? [String: Any] {
            self.id = dict["id"] as? String
            self.status = dict["status"] as? Bool
            self.msg = dict["msg"] as? String
            self.value = dict["value"]
        }
    }

    var debugDescription: String {
        return """
               \(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()) id: \(String(describing: id)), status: \(String(describing: status)), msg: \(String(describing: msg)),
               value: \(String(describing: value))
               """
    }
}
