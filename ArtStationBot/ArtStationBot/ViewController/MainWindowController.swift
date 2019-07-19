//
//  MainWindowController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import AppKit
import DLLogger

class MainWindowController: NSWindowController {
    private let log = Logger()
    private lazy var windowName: String = { NSStringFromClass(type(of: self)) }()
    private lazy var win: NSWindow = { return UI.createWindow() }()

    override init(window: NSWindow?) {
        super.init(window: window)
        //self.windowFrameAutosaveName = self.windowName
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {
        self.log.debug("main window controller did load")
    }

    func initUI() {
        self.win.contentViewController = MainViewController()
        self.shouldCascadeWindows = true
        self.contentViewController = win.contentViewController
        UI.setMainWindowBounds(self.win)
        self.window = self.win
    }

    func show() {
        self.showWindow(NSApp)
    }
}
