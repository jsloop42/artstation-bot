//
//  ASSecureTextField.swift
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

import Foundation
import AppKit
import DLLogger

class ASSecureTextField: NSSecureTextField {
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
    }
}
