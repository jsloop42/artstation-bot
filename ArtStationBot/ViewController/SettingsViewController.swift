//
//  SettingsViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

import Foundation
import AppKit
import DLLogger

class SettingsViewController: NSViewController {
    private let log = Logger()
    private var sview: SettingsView?
    private var topLevelObjects: NSArray?

    override func viewDidLoad() {
        self.log.debug("settings view controller did load")
        super.viewDidLoad()
    }

    override func loadView() {
        func createFromNib() -> NSView? {
            Bundle.main.loadNibNamed("SettingsView", owner: self, topLevelObjects: &self.topLevelObjects)
            guard let results = self.topLevelObjects else { return nil }
            let views = Array<Any>(results).filter { $0 is NSView }
            return views.last as? NSView
        }
        
        if let settingsView = createFromNib() {
            if let sview = settingsView as? SettingsView {
                self.sview = sview
                self.view = sview
            }
        }
    }
}

