//
//  ASTextField.swift
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

import Foundation
import AppKit
import DLLogger

class ASTextField: NSTextField {
    private let log = Logger()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func mouseDown(with event: NSEvent) {
        self.sendAction(#selector(didClick(_:)), to: self)
        super.mouseDown(with: event)
    }

    @objc func didClick(_ event: NSEvent) {
        self.log.debug("did click")
    }
}
