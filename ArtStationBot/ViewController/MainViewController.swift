//
//  MainViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Foundation
import AppKit
import DLLogger

class MainViewController: NSViewController {
    private let log = Logger()
    override func viewDidLoad() {
        self.log.debug("main view controller did load")
        initUI()
    }

    override func loadView() {
        self.view = NSView()
    }

    func initUI() {
        self.view.becomeFirstResponder()
    }
}
