//
//  WebKitWindowController.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import AppKit
import DLLogger

class WebKitWindowController: NSWindowController {
    private let log = Logger()
    lazy var windowName: String = { NSStringFromClass(type(of: self)) }()
    lazy var win: NSWindow = { return UI.createWindow() }()
    lazy var vc: WebKitViewController = { return WebKitViewController() }()

    override init(window: NSWindow?) {
        super.init(window: window)
        //self.windowFrameAutosaveName = self.windowName
        self.initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {
        self.log.debug("webkit window did load")
    }

    func initUI() {
        self.win.contentViewController = vc
        self.win.contentView = vc.webView
        self.shouldCascadeWindows = true
        self.contentViewController = self.win.contentViewController
        UI.setWindowBounds(self.win)
        self.window = self.win
    }

    func show() {
        self.showWindow(NSApp)
    }
}
