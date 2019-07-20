//
//  UI.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import AppKit

class UI {
    static func createMainWindow() {
        (MainWindowController()).show()
    }

    static func createWebKitWindow() -> WebKitWindowController {
        return WebKitWindowController()
    }

    static func createWindow() -> NSWindow {
        let window = NSWindow()
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.backingType = .buffered
        window.setFrame(NSRect(x: 0, y: 0, width: 500, height: 500), display: true)
        window.setFrameOriginToCenterOfScreen()
        return window
    }

    static func setMainWindowBounds(_ window: NSWindow) {
        if let screen = NSScreen.main {
            let size = screen.frame.size
            let percent: CGFloat = 0.6
            let offset: CGFloat = (1.0 - percent) / 2.0
            window.setFrame(NSMakeRect(size.width * offset, size.height * offset, size.width * percent, size.height * percent), display: true)
        }
    }

    static func setWindowBounds(_ window: NSWindow, width: CGFloat? = 500, height: CGFloat? = 500) {
        let w: CGFloat = { if let aw = width { return aw }; return 500 }()
        let h: CGFloat = { if let ah = height { return ah }; return 500 }()
        window.setFrame(NSMakeRect(NSApp.mainWindow!.frame.maxX, NSApp.mainWindow!.frame.maxY - h, w, h), display: true)
    }
}

extension NSWindow {
    public func setFrameOriginToCenterOfScreen() {
        if let screenSize = screen?.frame.size {
            self.setFrameOrigin(NSPoint(x: (screenSize.width - frame.size.width) / 2, y: (screenSize.height - frame.size.height) / 2))
        }
    }
}
