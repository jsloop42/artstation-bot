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
    private var columnIds: NSMutableArray = ["Skill Id", "Skill Name", "User Message"]
    private lazy var tableViewBuilder: ASTableViewBuilder = { return ASTableViewBuilder() }()
    private lazy var tableView: NSTableView = { return self.tableViewBuilder.tableView }()
    private lazy var tableScrollView: NSScrollView = {
        return self.tableViewBuilder.tableView(with: self.sview!.tableViewContainer, columns: UInt(self.columnIds.count), columnNames: self.columnIds,
                                               tableViewId: ASTableView.settings)
    }()
    private lazy var db: FoundationDBService = FoundationDBService.shared()
    private var skills: [Skill] = []
    private lazy var textFields: [NSTextField] = {
        return [self.sview!.emailTextField, self.sview!.passwordTextField, self.sview!.senderNameTextField, self.sview!.senderContactEmailTextField,
                self.sview!.senderURLTextField]
    }()
    private var isInEditMode = false
    private let frontierService = FrontierService.shared()
    private var shouldReloadCell = false
    private var currentEditRow = -1
    private var cellEditTimerDict: [Int: Timer] = [:]
    private let cellId = "msgCell"

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        initData()
        configUI()
        initEvents()
        super.viewWillAppear()
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
                sview.tableViewContainer.addSubview(self.tableScrollView)
                self.view = sview
            }
        }
    }

    func configUI() {
        let columns = self.tableView.tableColumns
        columns.forEach { col in
            if col.identifier.rawValue == self.columnIds[0] as! String || col.identifier.rawValue == self.columnIds[1] as! String {
                col.isEditable = false
            }
        }
        self.disableEditForAllTextFields()
        self.sview!.statusBarLabel.isHidden = true
        self.updateSenderDetailsInUI()
        NSApp.mainWindow!.initialFirstResponder = self.sview!.emailTextField
    }

    func updateSenderDetailsInUI() {
        if let sender = StateData.shared().senderDetails {
            self.sview!.emailTextField.stringValue = sender.artStationEmail
            self.sview!.senderNameTextField.stringValue = sender.name
            self.sview!.senderContactEmailTextField.stringValue = sender.contactEmail
            self.sview!.senderURLTextField.stringValue = sender.url
        }
    }

    func enableEditForAllTextFields() {
        DispatchQueue.main.async {
            self.textFields.forEach { tf in tf.isEditable = true }
            self.sview!.cancelEditBtn.isHidden = false
            self.sview!.credsEditBtn.isHidden = true
            self.sview!.emailTextField.becomeFirstResponder()
        }
    }

    func disableEditForAllTextFields() {
        DispatchQueue.main.async {
            self.textFields.forEach { tf in tf.isEditable = false }
            self.sview!.cancelEditBtn.isHidden = true
            self.sview!.credsEditBtn.isHidden = false
        }
    }

    func initEvents() {
        self.sview!.credsEditBtn.action = #selector(editBtnDidClick)
        self.sview!.cancelEditBtn.action = #selector(cancelEditBtnDidClick)
        NotificationCenter.default.addObserver(self, selector: #selector(tableViewShouldReload),
                                               name: NSNotification.Name(rawValue: ASNotification.settingsTableViewShouldReload), object: nil)
    }

    @objc func tableViewShouldReload() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc func editBtnDidClick() {
        if isInEditMode {  // => update button did click
            self.updateSenderDetails { status in
                if status {
                    self.disableEditForAllTextFields()
                    self.sview!.credsEditBtn.isHidden = false
                    self.sview!.credsEditBtn.image = NSImage(named: "edit")
                    self.sview!.passwordTextField.stringValue = ""  // clear password from the field
                    self.isInEditMode = false
                }
            }
        } else {
            // display update, cancel button
            self.enableEditForAllTextFields()
            self.sview!.cancelEditBtn.isHidden = false
            self.sview!.credsEditBtn.isHidden = false
            self.sview!.credsEditBtn.image = NSImage(named: "tick")
            self.isInEditMode = true
        }
    }

    func displayMessage(_ msg: String, isError: Bool) {
        self.sview!.statusBarLabel.isHidden = false
        self.sview!.statusBarLabel.stringValue = msg
        if isError {
            self.sview!.statusBarLabel.textColor = NSColor(red:1, green:0.149, blue:0, alpha:1)
        } else {
            self.sview!.statusBarLabel.textColor = Utils.isDarkMode() ? NSColor.white : NSColor.black
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.sview!.statusBarLabel.isHidden = true
        }
    }

    func updateSenderDetails(_ callback: @escaping (Bool) -> Void) {
        let artstationEmail = self.sview!.emailTextField.stringValue
        let password = self.sview!.passwordTextField.stringValue
        let name = self.sview!.senderNameTextField.stringValue
        let contactEmail = self.sview!.senderContactEmailTextField.stringValue
        let url = self.sview!.senderURLTextField.stringValue
        var isValid = true
        // Validate fields
        if artstationEmail.isEmpty {
            isValid = false
            self.displayMessage(UI.lmsg("Sender's ArtStation email address cannot be empty"), isError: true)
        } else if password.isEmpty {
            isValid = false
            self.displayMessage(UI.lmsg("Sender's ArtStation password cannot be empty"), isError: true)
        }
        if !isValid { callback(false); return }
        if !Utils.isValidEmail(artstationEmail) {
            isValid = false
            self.displayMessage(UI.lmsg("Sender's ArtStation email address is in invalid format"), isError: true)
            callback(false);
        }
        if !contactEmail.isEmpty && !Utils.isValidEmail(contactEmail) {
            isValid = false
            self.displayMessage(UI.lmsg("Sender's contact email is in invalid format"), isError: true)
            callback(false);
        }
        let senderDetails = SenderDetails()
        senderDetails.artStationEmail = artstationEmail
        senderDetails.password = password
        senderDetails.name = name
        senderDetails.contactEmail = contactEmail
        senderDetails.url = url
        self.frontierService.update(senderDetails, callback: { status in
            if status { StateData.shared().senderDetails = senderDetails }
            callback(status)
        })
    }

    @objc func cancelEditBtnDidClick() {
        self.isInEditMode = false
        self.disableEditForAllTextFields()
        self.sview!.credsEditBtn.image = NSImage(named: "edit")
    }

    func initData() {
        if StateData.shared().skills.count == 0 {
            self.db.getSkills {
                self.updateSkills()
            }
        } else {
            self.updateSkills()
        }
    }

    func updateSkills() {
        if let skills = StateData.shared().skills as? [Skill] {
            self.skills = skills
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func updateMessage(_ msg: String, for skill: Skill) {
        self.db.updateMessage(msg, for:skill) { status in
            DispatchQueue.main.async {
                if status {
                    skill.message = msg
                    skill.originalMessage = msg
                } else {
                    skill.message = skill.originalMessage
                    self.displayMessage(UI.lmsg("Error updating message"), isError: true)
                }
                self.tableView.reloadData()
            }
        }
    }
}

extension SettingsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.skills.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var textView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: self.cellId), owner: self) as? NSTextView
        guard let column = tableColumn else { return nil }
        if textView == nil {
            textView = NSTextView(frame: NSMakeRect(0, 0, column.width, 44))
            textView!.identifier = NSUserInterfaceItemIdentifier(rawValue: self.cellId)
            textView!.delegate = self
        }
        switch column.identifier.rawValue {
        case self.columnIds[0] as! String:
            textView!.string = String(format: "%ld", self.skills[row].skillId)
            textView!.isEditable = false
        case self.columnIds[1] as! String:
            textView!.string = self.skills[row].name
            textView!.isEditable = false
        case self.columnIds[2] as! String:
            textView!.string = self.skills[row].message
            textView!.isEditable = true
        default:
            textView!.string = ""
            textView!.isEditable = false
        }
        UI.setTableTextViewColor(textView!, row: row)
        return textView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let tv = NSTextView()
        tv.string = self.skills[row].message
        let frame = tv.frame
        if let last = self.tableView.tableColumns.last {
            tv.frame = NSMakeRect(0, 0, last.width, frame.height)
            tv.sizeToFit()
        }
        return tv.frame.height < 23 ? 23 : tv.frame.height
    }
}

extension SettingsViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            let row = self.tableView.row(for: textView)
            let skill = self.skills[row]
            skill.message = textView.string
            self.shouldReloadCell = false
            self.tableView.noteHeightOfRows(withIndexesChanged: IndexSet([row]))
            self.tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([0, 1, 2]))
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
                if let timer = self.cellEditTimerDict[row] { timer.invalidate() }
                let timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { timer in
                    timer.invalidate()
                    self.updateMessage(skill.message, for: skill)
                })
                self.cellEditTimerDict[row] = timer
            }
        }
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if replacementString == "\n" { // reload to update the cell height
            self.shouldReloadCell = true
        } else {
            self.shouldReloadCell = false
        }
        return true
    }
}
