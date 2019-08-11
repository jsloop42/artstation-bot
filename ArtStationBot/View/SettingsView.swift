//
//  SettingsView.swift
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

import Foundation
import AppKit
import DLLogger

class SettingsView: NSView {
    private let log = Logger()
    @IBOutlet weak var credsEditBtn: NSButton!
    @IBOutlet weak var emailTextField: ASTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var tableViewContainer: NSView!
    @IBOutlet weak var senderNameTextField: NSTextField!
    @IBOutlet weak var senderContactEmailTextField: NSTextField!
    @IBOutlet weak var senderURLTextField: NSTextField!
    @IBOutlet weak var cancelEditBtn: NSButton!
    @IBOutlet weak var statusBarLabel: NSTextField!
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    override func layout() {
        self.log.debug("layout method")
        super.layout()
    }
}
