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
        self.view.becomeFirstResponder()
    }

    @objc func testButtonDidClick() {
        self.log.debug("btn did click")
        let wkwc = UI.createWebKitWindow()
        wkwc.vc.setShouldSignIn(true)
        wkwc.show()
    }
}
