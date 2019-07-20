//
//  MainViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import AppKit
import WebKit
import DLLogger

class MainViewController: NSViewController {
    private let log = Logger()
    private lazy var btn: NSButton = {
        let b = NSButton(title: "Test", target: self, action: #selector(testButtonDidClick))
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private lazy var dashboardBtn: NSButton = {
        let b = NSButton(title: "Dashboard", target: self, action: #selector(dashboardButtonDidClick))
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private lazy var crawlerBtn: NSButton = {
        let b = NSButton(title: "Crawler", target: self, action: #selector(crawlerButtonDidClick))
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private lazy var messengerBtn: NSButton = {
        let b = NSButton(title: "Messenger", target: self, action: #selector(messengerButtonDidClick))
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        self.log.debug("main view controller did load")
        initUI()
    }

    override func loadView() {
        self.view = NSView()
    }

    func initUI() {
        self.view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
            btn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            btn.widthAnchor.constraint(equalToConstant: 100),
            btn.heightAnchor.constraint(equalToConstant: 20)
        ])
        self.view.addSubview(self.dashboardBtn)
        self.view.addSubview(self.crawlerBtn)
        self.view.addSubview(self.messengerBtn)
        self.dashboardBtn.focusRingType = .none
        self.crawlerBtn.focusRingType = .none
        self.messengerBtn.focusRingType = .none
        NSLayoutConstraint.activate([
            self.dashboardBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
            self.dashboardBtn.trailingAnchor.constraint(equalTo: self.crawlerBtn.leadingAnchor, constant: -8),
            self.dashboardBtn.widthAnchor.constraint(equalToConstant: 100)
        ])
        NSLayoutConstraint.activate([
            self.crawlerBtn.topAnchor.constraint(equalTo: self.dashboardBtn.topAnchor, constant: 0),
            self.crawlerBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            self.crawlerBtn.widthAnchor.constraint(equalToConstant: 100)
        ])
        NSLayoutConstraint.activate([
            self.messengerBtn.topAnchor.constraint(equalTo: self.dashboardBtn.topAnchor, constant: 0),
            self.messengerBtn.leadingAnchor.constraint(equalTo: self.crawlerBtn.trailingAnchor, constant: 8),
            self.messengerBtn.widthAnchor.constraint(equalToConstant: 100)
        ])
        self.dashboardButtonDidClick()
        self.view.becomeFirstResponder()
    }

    @objc func dashboardButtonDidClick() {
        self.log.debug("dashboard button did click")
        self.dashboardBtn.isBordered = true
        self.crawlerBtn.isBordered = false
        self.messengerBtn.isBordered = false
        self.dashboardBtn.highlight(true)
        self.crawlerBtn.highlight(false)
        self.messengerBtn.highlight(false)
    }

    @objc func crawlerButtonDidClick() {
        self.log.debug("crawler button did click")
        self.dashboardBtn.isBordered = false
        self.crawlerBtn.isBordered = true
        self.messengerBtn.isBordered = false
        self.dashboardBtn.highlight(false)
        self.crawlerBtn.highlight(true)
        self.messengerBtn.highlight(false)
    }

    @objc func messengerButtonDidClick() {
        self.log.debug("messenger button did click")
        self.dashboardBtn.isBordered = false
        self.crawlerBtn.isBordered = false
        self.messengerBtn.isBordered = true
        self.dashboardBtn.highlight(false)
        self.crawlerBtn.highlight(false)
        self.messengerBtn.highlight(true)
    }

    @objc func testButtonDidClick() {
        self.log.debug("btn did click")
        let wkwc = UI.createWebKitWindow()
        wkwc.vc.setShouldSignIn(true)
        wkwc.show()
    }
}
