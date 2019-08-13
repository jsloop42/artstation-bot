//
//  AppDelegate.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Cocoa
import DLLogger

class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger()

    override init() {
        _ = FoundationDBService.shared().initDocLayer()
        UI.createMainWindow()
        StateData.shared().isDarkMode = Utils.isDarkMode()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initEvents()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func initEvents() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(themeChanged(_:)),
                                                            name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }

    @objc func themeChanged(_ notif: NSNotification) {
        StateData.shared().isDarkMode = Utils.isDarkMode()
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: ASNotification.settingsTableViewShouldReload)))
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ArtStationBot")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        let context = persistentContainer.viewContext
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let context = persistentContainer.viewContext
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        if !context.hasChanges {
            return .terminateNow
        }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        return .terminateNow
    }

}

