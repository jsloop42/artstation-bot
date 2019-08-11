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
