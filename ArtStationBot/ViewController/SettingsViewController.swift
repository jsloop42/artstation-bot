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
        return self.tableViewBuilder.tableView(with: self.sview!.tableViewContainer, columns: UInt(self.columnIds.count), columnNames: self.columnIds)
    }()
    private lazy var db: FoundationDBService = FoundationDBService.shared()
    private var skills: [Skill] = []

    override func viewDidLoad() {
        self.log.debug("settings view controller did load")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        initData()
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
}

extension SettingsViewController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.skills.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let column = tableColumn {
            let id = column.identifier.rawValue
            switch id {
            case columnIds[0] as! String:
                return String(format: "%ld", self.skills[row].skillId)
            case columnIds[1] as! String:
                return self.skills[row].name
            case columnIds[2] as! String:
                return self.skills[row].message
            default:
                return ""
            }
        }

        return ""
    }
}
