//
//  UI.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Foundation
import AppKit

@objc
@objcMembers
class UI: NSObject {
    private static var enStringBundle: Bundle?
    private static var topLevelObjects: NSArray?

    static func createMainWindow() {
        (MainWindowController()).show()
    }

    static func createWebKitWindow() -> WebKitWindowController {
        return WebKitWindowController()
    }

    static func createWindow() -> NSWindow {
        let window = NSWindow()
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.backingType = .buffered
        window.setFrame(NSRect(x: 0, y: 0, width: 500, height: 500), display: true)
        window.setFrameOriginToCenterOfScreen()
        return window
    }

    static func createFromNib(_ nibName: String) -> NSView? {
        self.topLevelObjects = nil
        Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: &self.topLevelObjects)
        guard let results = self.topLevelObjects else { return nil }
        let views = Array<Any>(results).filter { $0 is NSView }
        return views.last as? NSView
    }

    static func setMainWindowBounds(_ window: NSWindow) {
        if let screen = NSScreen.main {
            let size = screen.frame.size
            let percent: CGFloat = 0.6
            let offset: CGFloat = (1.0 - percent) / 2.0
            window.setFrame(NSMakeRect(size.width * offset, size.height * offset, size.width * percent, size.height * percent), display: true)
        }
    }

    static func setWindowBounds(_ window: NSWindow, width: CGFloat? = 500, height: CGFloat? = 500) {
        let w: CGFloat = { if let aw = width { return aw }; return 500 }()
        let h: CGFloat = { if let ah = height { return ah }; return 500 }()
        if let mainWindow = NSApp.mainWindow {
            window.setFrame(NSMakeRect(mainWindow.frame.maxX, mainWindow.frame.maxY - h, w, h), display: true)
        }
    }

    static func createToolbar(id: NSToolbar.Identifier) -> NSToolbar {
        let toolbar = NSToolbar(identifier: id)
        toolbar.allowsUserCustomization = true
        toolbar.displayMode = .iconAndLabel
        return toolbar
    }

    static func createSegmentedControl(labels: [String], action: Selector) -> NSSegmentedControl {
        let sc = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: action)
        sc.setSelected(true, forSegment: 0)
        return sc
    }

    static func createButton() -> NSButton {
        let btn = NSButton(frame: NSMakeRect(0, 0, 40, 40))
        btn.setButtonType(.momentaryPushIn)
        btn.bezelStyle = .texturedRounded
        return btn
    }

    static func createStackView() -> NSStackView {
        let sv = NSStackView(frame: NSMakeRect(0, 0, 0, 0))
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.distribution = .fill
        sv.alignment = .left
        sv.orientation = .vertical
        return sv
    }

    static func lmsg(_ key: String) -> String {
        return lmsg(key, "en")  // Using en as default as there is only one localization at present
    }

    /// Returns the localized string
    /// - Parameter key: Localization string key
    static func lmsg(_ key: String, _ lang: String) -> String {
        switch lang {
        case "en":
            if let enBundle = enStringBundle {
                return NSLocalizedString(key, tableName: nil, bundle: enBundle, value: "", comment: "")
            } else {
                loadBundle(for: lang)
                return lmsg(key, lang)
            }
        default:
            break
        }
        return NSLocalizedString(key, comment: "")
    }

    static func loadBundle(for lang: String) {
        let mainBundle = Bundle(for: self)
        if let path = mainBundle.path(forResource: lang, ofType: "lproj") {
            if lang == "en" { self.enStringBundle = Bundle(path: path) }
        }
    }

    static func setTableTextViewColor(_ textView: NSTextView, row: Int) {
        textView.textColor = Utils.isDarkMode() ? NSColor.white : NSColor.black
        if row % 2 == 0 {
            textView.backgroundColor = Utils.isDarkMode() ? NSColor(red:37/255, green:38/255, blue:36/255, alpha:1)
                                                          : NSColor(red:255/255, green:255/255, blue:255/255, alpha:1)
        } else {
            textView.backgroundColor = Utils.isDarkMode() ? NSColor(red:47/255, green:48/255, blue:46/255, alpha:1)
                                                          : NSColor(red:244/255, green:244/255, blue:245/255, alpha:1)
        }
    }
}

extension NSWindow {
    public func setFrameOriginToCenterOfScreen() {
        if let screenSize = screen?.frame.size {
            self.setFrameOrigin(NSPoint(x: (screenSize.width - frame.size.width) / 2, y: (screenSize.height - frame.size.height) / 2))
        }
    }
}
