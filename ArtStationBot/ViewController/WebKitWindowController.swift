//
//  WebKitWindowController.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//

import Foundation
import AppKit
import DLLogger

@objc
protocol WebKitControllerDelegate {
    func webKitWindowDidLoad()
}

@objc
@objcMembers
class WebKitWindowController: NSWindowController {
    private let log = Logger()
    lazy var windowName: String = { NSStringFromClass(type(of: self)) }()
    lazy var win: NSWindow = { return UI.createWindow() }()
    lazy var vc: WebKitViewController = { return WebKitViewController() }()
    var delegate: WebKitControllerDelegate?

    override init(window: NSWindow?) {
        super.init(window: window)
        self.initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    func getWindow() -> NSWindow {
        return self.win
    }


    func getViewController() -> WebKitViewController {
        return self.vc
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
        self.delegate?.webKitWindowDidLoad()
    }
}
