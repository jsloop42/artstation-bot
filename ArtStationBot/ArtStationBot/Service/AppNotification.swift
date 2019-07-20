//
//  AppNotification.swift
//  ArtStationBot
//
//  Created by jsloop on 26/03/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import DLLogger

protocol NotificationData {
    func getData() -> Any?
    mutating func setData(data: Any?)
}

/// A `UserInfo` data passed with `Notification`.
struct NotifInfo: NotificationData {
    private var data: Any?

    init() {}

    init(_ data: Any) {
        self.data = data
    }

    func getData() -> Any? {
        return data
    }
    
    mutating func setData(data: Any?) {
        self.data = data
    }
}

typealias AppNotif = AppNotification

/// A class used for working with `Notification`. There are options for observing as well as posting notifications.
class AppNotification {
    private var notifCenter: NotificationCenter
    private var notifs: [Any?] = []
    private let log = Logger()
    private static var shared: AppNotification?

    init(_ notifCenter: NotificationCenter) {
        self.notifCenter = notifCenter
    }

    init() {
        self.notifCenter = NotificationCenter.default
    }

    static func getInstance() -> AppNotification {
        if let shared = shared { return shared }
        shared = AppNotification()
        return shared!
    }

    static func setInstance(_ this: AppNotification) {
        shared = this
    }

    func deinitListeners(_ obs: [Any?]) {
        _ = obs.map {
            if let obs = $0 {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }
    
    func getNotificationCenter() -> NotificationCenter {
        return notifCenter
    }

    func post(_ notification: Notification.Name, sender: Any? = nil) {
        notifCenter.post(name: notification, object: sender ?? self)
    }

    func post(_ notification: Notification.Name, sender: Any? = nil, data: NotifInfo) {
        notifCenter.post(name: notification, object: sender ?? self, userInfo: ["data": data as Any])
    }

    func receive(_ notification: Notification.Name, callback: @escaping () -> Void) -> NSObjectProtocol {
        let notif = notifCenter.addObserver(forName: notification, object: nil, queue: nil, using: { _ in
            callback()
        })
        return notif
    }

    func receive(_ notification: Notification.Name, callback: @escaping (_ data: NotifInfo) -> Void) -> NSObjectProtocol {
        let notif = notifCenter.addObserver(forName: notification, object: nil, queue: nil, using: { notif in
            if let userInfo = notif.userInfo {
                if let info = userInfo["data"] as? NotifInfo {
                    callback(info)
                }
            }
        })
        return notif
    }
    
    func receive(_ notification: Notification.Name, callback: @escaping (_ notification: Notification) -> Void) -> NSObjectProtocol {
        let notif = notifCenter.addObserver(forName: notification, object: nil, queue: nil, using: { notif in
            callback(notif)
        })
        return notif
    }
}

extension AppNotification {
    struct Events {
        static let isSignedIn = Notification.Name("isSignedInNotification")
    }
}
