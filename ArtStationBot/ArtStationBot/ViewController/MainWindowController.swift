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
    private lazy var toolbar: NSToolbar = { return UI.createToolbar(id: self.toolbarId) }()
    private lazy var tabbar: NSSegmentedControl = { return UI.createTabbar(labels: ["Dashboard", "Crawler", "Messenger"]) }()
    private lazy var toolbarId: NSToolbar.Identifier = { return NSToolbar.Identifier("mainToolbar") }()
    private lazy var toolbarCrawlBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarCrawlButton") }()
    private lazy var toolbarMessageBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarMessageButton") }()
    private lazy var toolbarCredsBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarCredentialButton") }()
    private lazy var toolbarSegmentedControlId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarSegmentedControl") }()
    private lazy var crawlBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = "Crawler"
        btn.toolTip = "Start Crawler"
        return btn
    }()
    private lazy var messageBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = "Message"
        btn.toolTip = "Start Messenger"
        return btn
    }()
    private lazy var credsBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = "Credential"
        btn.toolTip = "Set credentials"
        return btn
    }()

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
        self.toolbar.delegate = self
        //self.window?.titleVisibility = .hidden
        //self.window?.title = "ArtStation Bot"
        self.window?.toolbar = self.toolbar
    }

    func show() {
        self.showWindow(NSApp)
    }
}

// MARK: - Toolbar delegate
extension MainWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem!
        switch itemIdentifier {
        case self.toolbarSegmentedControlId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.view = self.tabbar
        case self.toolbarCrawlBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Crawl"
            toolbarItem.view = self.crawlBtn
        case self.toolbarMessageBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Message"
            toolbarItem.view = self.messageBtn
        case self.toolbarCredsBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = "Credential"
            toolbarItem.view = self.credsBtn
        case .flexibleSpace:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        case .separator:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        default:
            self.log.debug("toolbar item id: \(itemIdentifier)")
        }
        return toolbarItem
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [self.toolbarCrawlBtnId, self.toolbarMessageBtnId, .separator, self.toolbarCredsBtnId, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [self.toolbarCrawlBtnId, self.toolbarMessageBtnId, .separator, self.toolbarCredsBtnId, .flexibleSpace]
    }
}
