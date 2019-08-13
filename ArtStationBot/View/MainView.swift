//
//  MainView.swift
//  ArtStationBot
//
//  Created by jsloop on 12/08/19.
//

import Cocoa

class MainView: NSView {
    @IBOutlet weak var crawlerScheduleView: NSView!
    @IBOutlet weak var crawlerProgressView: NSView!
    @IBOutlet weak var messageScheduleView: NSView!
    @IBOutlet weak var messageProgressView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    var crawlScheduleTableViewBuilder: ASTableViewBuilder = ASTableViewBuilder()
    lazy var crawlScheduleTableView: NSTableView = { return self.crawlScheduleTableViewBuilder.tableView }()
    lazy var crawlerScheduleTableScrollView: NSScrollView = {
        return self.crawlScheduleTableViewBuilder.tableView(with: self.crawlerScheduleView, columns: UInt(self.crawlerScheduleColumnIds.count),
                                                            columnNames: self.crawlerScheduleColumnIds, tableViewId: ASTableView.crawlSchedule)
    }()
    var crawlProgressTableViewBuilder: ASTableViewBuilder = ASTableViewBuilder()
    lazy var crawlProgressTableView: NSTableView = { return self.crawlProgressTableViewBuilder.tableView }()
    lazy var crawlerProgressTableScrollView: NSScrollView = {
        return self.crawlProgressTableViewBuilder.tableView(with: self.crawlerProgressView, columns: UInt(self.crawlerProgressColumnIds.count),
                                                            columnNames: self.crawlerProgressColumnIds, tableViewId: ASTableView.crawlProgress)
    }()
    var messageScheduleTableViewBuilder: ASTableViewBuilder = ASTableViewBuilder()
    lazy var messageScheduleTableView: NSTableView = { return self.messageScheduleTableViewBuilder.tableView }()
    lazy var messageScheduleTableScrollView: NSScrollView = {
        return self.messageScheduleTableViewBuilder.tableView(with: self.messageScheduleView, columns: UInt(self.messageScheduleColumnIds.count),
                                                            columnNames: self.messageScheduleColumnIds, tableViewId: ASTableView.messageSchedule)
    }()
    var messageProgressTableViewBuilder: ASTableViewBuilder = ASTableViewBuilder()
    lazy var messageProgressTableView: NSTableView = { return self.messageProgressTableViewBuilder.tableView }()
    lazy var messageProgressTableScrollView: NSScrollView = {
        return self.messageProgressTableViewBuilder.tableView(with: self.messageProgressView, columns: UInt(self.messageProgressColumnIds.count),
                                                              columnNames: self.messageProgressColumnIds, tableViewId: ASTableView.messageProgress)
    }()
    let crawlerScheduleCellId = "crawlerScheduleCellId"
    let crawlerProgressCellId = "crawlerProgressCellId"
    let messageScheduleCellId = "messageScheduleCellId"
    let messageProgressCellId = "messageProgressCellId"
    var crawlerScheduleColumnIds: NSMutableArray = ["Skill Id", "Skill Name", "Page", "Scheduled Time"]
    var crawlerProgressColumnIds: NSMutableArray = ["Skill Id", "Skill Name", "Page"]
    var messageScheduleColumnIds: NSMutableArray = ["User Id", "User's Fullname", "Profile URL", "Skill Name", "Scheduled Time"]
    var messageProgressColumnIds: NSMutableArray = ["User Id", "User's Fullname", "Profile URL", "Skill Name"]
    var crawlerScheduleData: [DashboardViewModel] = []
    var crawlerProgressData: [DashboardViewModel] = []
    var messageScheduleData: [DashboardViewModel] = []
    var messageProgressData: [DashboardViewModel] = []

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        initUI()
    }

    func initUI() {
        self.statusLabel.isHidden = true
        self.crawlerScheduleView.addSubview(self.crawlerScheduleTableScrollView)
        self.crawlerProgressView.addSubview(self.crawlerProgressTableScrollView)
        self.messageScheduleView.addSubview(self.messageScheduleTableScrollView)
        self.messageProgressView.addSubview(self.messageProgressTableScrollView)
        self.crawlScheduleTableView.sizeToFit()
        self.crawlProgressTableView.sizeToFit()
        self.messageScheduleTableView.sizeToFit()
        self.messageProgressTableView.sizeToFit()
        self.crawlScheduleTableView.delegate = self
        self.crawlScheduleTableView.dataSource = self
        self.crawlProgressTableView.delegate = self
        self.crawlProgressTableView.dataSource = self
        self.messageScheduleTableView.delegate = self
        self.messageScheduleTableView.dataSource = self
        self.messageProgressTableView.delegate = self
        self.messageProgressTableView.dataSource = self
    }
}

extension MainView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case self.crawlScheduleTableView:
            return self.crawlerScheduleData.count
        case self.crawlProgressTableView:
            return self.crawlerProgressData.count
        case self.messageScheduleTableView:
            return self.messageProgressData.count
        case self.messageProgressTableView:
            return self.messageProgressData.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == self.crawlScheduleTableView {
            return self.getTextViewForTable(.crawlSchedule, cellId: self.crawlerScheduleCellId, tableView: tableView, viewFor: tableColumn, row: row,
                                            data: self.crawlerScheduleData[row], columnIds: self.crawlerScheduleColumnIds)
        } else if tableView == self.crawlProgressTableView {
            return self.getTextViewForTable(.crawlProgress, cellId: self.crawlerProgressCellId, tableView: tableView, viewFor: tableColumn, row: row,
                                            data: self.crawlerProgressData[row], columnIds: self.crawlerProgressColumnIds)
        } else if tableView == self.messageScheduleTableView {
            return self.getTextViewForTable(.messageSchedule, cellId: self.messageScheduleCellId, tableView: tableView, viewFor: tableColumn, row: row,
                                            data: self.messageScheduleData[row], columnIds: self.messageScheduleColumnIds)
        }
        return self.getTextViewForTable(.messageProgress, cellId: self.messageProgressCellId, tableView: tableView, viewFor: tableColumn, row: row,
                                        data: self.messageProgressData[row], columnIds: self.messageProgressColumnIds)
    }

    func getTextViewForTable(_ tableId: ASTableView, cellId: String, tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int,
                             data: DashboardViewModel, columnIds: NSMutableArray) -> NSView? {
        var textView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? NSTextView
        guard let column = tableColumn else { return nil }
        if textView == nil {
            textView = NSTextView(frame: NSMakeRect(0, 0, column.width, 44))
            textView!.identifier = NSUserInterfaceItemIdentifier(rawValue: cellId)
            //textView!.delegate = self
        }
        let columnId = column.identifier.rawValue
        textView!.isEditable = false
        textView!.isSelectable = true
        if tableId == .crawlSchedule {
            if columnId == columnIds[0] as! String {
                textView!.string = String(format: "%ld", data.skill.skillId)
            } else if columnId == columnIds[1] as! String {
                textView!.string = data.skill.name
            } else if columnId == columnIds[2] as! String {
                textView!.string = String(format: "%ld", data.page)
            } else if columnId == columnIds[3] as! String {
                textView!.string = Utils.getTimeStringFromDate(data.scheduledDate)
            }
        } else if tableId == .crawlProgress {
            if columnId == columnIds[0] as! String {
                textView!.string = String(format: "%ld", data.skill.skillId)
            } else if columnId == columnIds[1] as! String {
                textView!.string = data.skill.name
            } else if columnId == columnIds[2] as! String {
                textView!.string = String(format: "%ld", data.page)
            }
        } else if tableId == .messageSchedule {
            if columnId == columnIds[0] as! String {
                textView!.string = String(format: "%ld", data.user.userId)
            } else if columnId == columnIds[1] as! String {
                textView!.string = data.user.fullName
            } else if columnId == columnIds[2] as! String {
                textView!.string = data.user.artstationProfileURL
            } else if columnId == columnIds[3] as! String {
                textView!.string = data.skill.name
            } else if columnId == columnIds[4] as! String {
                textView!.string = Utils.getTimeStringFromDate(data.scheduledDate)
            }
        } else if tableId == .messageProgress {
            if columnId == columnIds[0] as! String {
                textView!.string = String(format: "%ld", data.user.userId)
            } else if columnId == columnIds[1] as! String {
                textView!.string = data.user.fullName
            } else if columnId == columnIds[2] as! String {
                textView!.string = data.user.artstationProfileURL
            } else if columnId == columnIds[3] as! String {
                textView!.string = data.skill.name
            }
        }
        UI.setTableTextViewColor(textView!, row: row)
        return textView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var isMessageTable = false
        let model: DashboardViewModel? = {
            if tableView == self.crawlScheduleTableView {
                if self.crawlerScheduleData.count > row { return self.crawlerScheduleData[row] }
                return nil
            }
            if tableView == self.crawlProgressTableView {
                if self.crawlerProgressData.count > row { return self.crawlerProgressData[row] }
                return nil
            }
            if tableView == self.messageScheduleTableView {
                isMessageTable = true
                if self.messageScheduleData.count > row { return self.messageScheduleData[row] }
                return nil
            }
            isMessageTable = true
            return self.messageProgressData.count > row ? self.messageProgressData[row] : nil
        }()
        if !isMessageTable { return 44 }
        if let aModel = model {
            let content = aModel.user.artstationProfileURL
            let tv = NSTextView()
            tv.string = content
            let frame = tv.frame
            if let last = tableView.tableColumns.last {
                tv.frame = NSMakeRect(0, 0, last.width, frame.height)
                tv.sizeToFit()
            }
            return tv.frame.height < 33 ? 33 : tv.frame.height
        }
        return 33
    }
}
