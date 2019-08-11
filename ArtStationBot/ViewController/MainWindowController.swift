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
    private lazy var frontierService = { return FrontierService.shared() }()
    private lazy var crawlService = { return CrawlService() }()
    private lazy var dbService = { return FoundationDBService.shared() }()
    private lazy var windowName: String = { NSStringFromClass(type(of: self)) }()
    private lazy var win: NSWindow = { return UI.createWindow() }()
    private lazy var mainWindowVC: MainViewController = { return MainViewController() }()
    private lazy var settingsWindowVC: SettingsViewController = { return SettingsViewController() }()
    private lazy var toolbar: NSToolbar = { return UI.createToolbar(id: self.toolbarId) }()
    private lazy var segmentedControl: NSSegmentedControl = {
        return UI.createSegmentedControl(labels: [UI.lmsg("Dashboard"), UI.lmsg("Data"), UI.lmsg("Settings")],
                                         action: #selector(MainWindowController.segmentedControlDidClick(sender:)))
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
    private lazy var webkitWindow: WebKitWindowController = { return UI.createWebKitWindow() }()
    private var segmentSelectedIndex: Int = 0

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
        self.win.contentViewController = self.mainWindowVC
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
        self.webkitWindow.vc.setShouldSignIn(false)
    }

    func initEvents() {
        self.crawlBtn.action = #selector(crawlButtonDidClick)
        self.messageBtn.action = #selector(messageButtonDidClick)
    }

    @objc func segmentedControlDidClick(sender: NSSegmentedControl) {
        print("segmented control index: \(sender.selectedSegment)")
        if self.segmentSelectedIndex == sender.selectedSegment { return }
        self.segmentSelectedIndex = sender.selectedSegment
        if sender.selectedSegment == 2 {  // Settings
            self.window!.contentViewController = self.settingsWindowVC
            UI.setMainWindowBounds(self.window!)
        } else if sender.selectedSegment == 1 {  // Data

        } else if sender.selectedSegment == 0 {  // Dashboard
            self.window!.contentViewController = self.mainWindowVC
            UI.setMainWindowBounds(self.window!)
        }
    }
}

// MARK: - Event handlers
extension MainWindowController {
    @objc func crawlButtonDidClick() {
        self.frontierService.isCrawlPaused ? self.frontierService.startCrawl() : self.frontierService.pauseCrawl()
    }

    @objc func messageButtonDidClick() {
        self.webkitWindow.show()
        //self.webkitWindow.vc.setShouldSignIn(true)
        self.frontierService.isMessengerPaused ? self.frontierService.startMessenger() : self.frontierService.pauseMessenger()
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
        case self.dspaceId:
            toolbarItem = self.dspace
        default:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        }
        return toolbarItem
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [self.toolbarCrawlBtnId, self.toolbarMessageBtnId, self.toolbarSegmentedControlId, self.dspaceId, .space, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarItems
    }
}
