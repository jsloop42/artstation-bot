//
//  MainWindowController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Foundation
import AppKit
import DLDynamicSpace
import DLLogger

class MainWindowController: NSWindowController {
    private let log = Logger()
    private lazy var crawlService = { return CrawlService() }()
    private lazy var dbService = { return FoundationDBService.shared() }()
    private lazy var windowName: String = { NSStringFromClass(type(of: self)) }()
    private lazy var win: NSWindow = { return UI.createWindow() }()
    private lazy var toolbar: NSToolbar = { return UI.createToolbar(id: self.toolbarId) }()
    private lazy var segmentedControl: NSSegmentedControl = {
        return UI.createSegmentedControl(labels: [UI.lmsg("Dashboard"), UI.lmsg("Crawler"), UI.lmsg("Messenger")])
    }()
    private lazy var toolbarId: NSToolbar.Identifier = { return NSToolbar.Identifier("mainToolbar") }()
    private lazy var toolbarCrawlBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarCrawlButton") }()
    private lazy var toolbarMessageBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarMessageButton") }()
    private lazy var toolbarCredsBtnId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarCredentialButton") }()
    private lazy var toolbarSegmentedControlId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarSegmentedControl") }()
    private lazy var crawlBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = UI.lmsg("Crawl")
        btn.toolTip = UI.lmsg("Start Crawler")
        return btn
    }()
    private lazy var messageBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = UI.lmsg("Message")
        btn.toolTip = UI.lmsg("Start Messenger")
        return btn
    }()
    private lazy var credsBtn: NSButton = {
        let btn = UI.createButton()
        btn.title = UI.lmsg("Credential")
        btn.toolTip = UI.lmsg("Set credentials")
        return btn
    }()
    private lazy var dspaceId: NSToolbarItem.Identifier = { return NSToolbarItem.Identifier("mainToolbarDynamicSpace") }()
    private lazy var dspace: DynamicSpace = { return DynamicSpace(itemIdentifier: self.dspaceId) }()
    private lazy var toolbarItems: [NSToolbarItem.Identifier] = {
        var xs = [self.toolbarCrawlBtnId, self.toolbarMessageBtnId, self.toolbarCredsBtnId, self.toolbarSegmentedControlId, .flexibleSpace]
        if #available(OSX 10.14, *) {
            self.toolbar.centeredItemIdentifier = self.toolbarSegmentedControlId
            return xs
        }
        xs.insert(self.dspaceId, at: 3)
        return xs
    }()

    override init(window: NSWindow?) {
        super.init(window: window)
        //self.windowFrameAutosaveName = self.windowName
        initUI()
        initEvents()
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
        self.toolbar.displayMode = .iconOnly
        self.toolbar.allowsUserCustomization = true
        self.window?.titleVisibility = .hidden
        //self.window?.title = "ArtStation Bot"
        self.window?.toolbar = self.toolbar
    }

    func show() {
        self.showWindow(NSApp)
    }

    func initEvents() {
        self.crawlBtn.action = #selector(crawlButtonDidClick)
    }
}

// MARK: - Event handlers
extension MainWindowController {
    @objc func crawlButtonDidClick() {
//        self.crawlService.getCSRFToken { token in
//            self.log.debug("CSRF token: \(token)")
//            self.crawlService.getFilterList { filters in
//                self.log.debug("Filters: \(filters)")
//                self.dbService.insert(filters, callback: { status in
//                    DispatchQueue.main.async {
//                        self.log.debug("Filters insert status: \(status)")
//                    }
//                })
//            }
//        }
        //self.dbService.test()
//        self.dbService.getUsersWithOffset(1, limit: 2, callback: { users in
//            self.log.debug(users)
//        })
    }
}

// MARK: - Toolbar delegate
extension MainWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem!
        switch itemIdentifier {
        case self.toolbarSegmentedControlId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.view = self.segmentedControl
        case self.toolbarCrawlBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = UI.lmsg("Crawl")
            toolbarItem.view = self.crawlBtn
        case self.toolbarMessageBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = UI.lmsg("Message")
            toolbarItem.view = self.messageBtn
        case self.toolbarCredsBtnId:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.label = UI.lmsg("Credential")
            toolbarItem.view = self.credsBtn
        case self.dspaceId:
            toolbarItem = self.dspace
        default:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        }
        return toolbarItem
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [self.toolbarCrawlBtnId, self.toolbarMessageBtnId, self.toolbarCredsBtnId, self.toolbarSegmentedControlId, self.dspaceId, .space, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarItems
    }
}
