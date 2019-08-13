//
//  MainViewController.swift
//  ArtStationBot
//
//  Created by jsloop on 19/07/19.
//

import Foundation
import AppKit
import DLLogger

class MainViewController: NSViewController {
    private let log = Logger()
    private let fdbService = FoundationDBService.shared()
    private let frontierService = FrontierService.shared()
    var crawlScheduleData: [DashboardViewModel] = []
    var crawlProgressData: [DashboardViewModel] = []
    var messageScheduleData: [DashboardViewModel] = []
    var messageProgressData: [DashboardViewModel] = []

    override func viewDidLoad() {
        self.log.debug("main view controller did load")
        initUI()
        initEvents()
        updateData()
    }

    override func loadView() {
        if let mview = UI.createFromNib("MainView") as? MainView {
            self.view = mview
        } else {
            self.view = NSView()
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    func initUI() {
        self.view.becomeFirstResponder()
    }

    func initEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateData),
                                               name: NSNotification.Name(rawValue: ASNotification.dashboardTableViewShouldReload), object: nil)
    }

    @objc func updateData() {
        // crawler schedule
        self.crawlScheduleData.removeAll()
        var keys = self.frontierService.fetchTable.allKeys
        for key in keys {
            if let state = self.frontierService.fetchTable.object(forKey: key) as? UserFetchState {
                let model = self.getModelFromCrawlState(state)
                model.tableViewType = .crawlSchedule
                self.crawlScheduleData.append(model)
            }
        }
        // crawl in progress
        self.crawlProgressData.removeAll()
        keys = self.frontierService.crawlerRunTable.allKeys
        for key in keys {
            if let state = self.frontierService.crawlerRunTable.object(forKey: key) as? UserFetchState {
                let model = self.getModelFromCrawlState(state)
                model.tableViewType = .crawlProgress
                self.crawlProgressData.append(model)
            }
        }
        // message schedule
        keys = self.frontierService.messageTable.allKeys
        self.messageScheduleData.removeAll()
        for key in keys {
            if let state = self.frontierService.messageTable.object(forKey: key) as? UserMessageState {
                let model = self.getModelFromMessageState(state)
                model.tableViewType = .messageSchedule
                self.messageScheduleData.append(model)
            }
        }
        // message in progress
        self.messageProgressData.removeAll()
        keys = self.frontierService.messengerRunTable.allKeys
        for key in keys {
            if let state = self.frontierService.messengerRunTable.object(forKey: key) as? UserMessageState {
                let model = self.getModelFromMessageState(state)
                model.tableViewType = .messageProgress
                self.messageProgressData.append(model)
            }
        }
        if let mview = self.view as? MainView {
            mview.crawlerScheduleData = self.crawlScheduleData
            mview.crawlerProgressData = self.crawlProgressData
            mview.messageScheduleData = self.messageScheduleData
            mview.messageProgressData = self.messageProgressData
            DispatchQueue.main.async {
                mview.crawlScheduleTableView.sizeToFit()
                mview.crawlProgressTableView.sizeToFit()
                mview.messageScheduleTableView.sizeToFit()
                mview.messageProgressTableView.sizeToFit()
                mview.crawlScheduleTableView.reloadData()
                mview.crawlProgressTableView.reloadData()
                mview.messageScheduleTableView.reloadData()
                mview.messageProgressTableView.reloadData()
            }
        }
    }

    func getModelFromCrawlState(_ state: UserFetchState) -> DashboardViewModel {
        let model = DashboardViewModel()
        model.page = state.page
        if let skillId = UInt(state.skillId), let skills = StateData.shared().skills.filtered(using: NSPredicate(format: "skillId = %d", skillId)) as? [Skill],
            skills.count == 1 {
            model.skill = skills[0]
        }
        model.scheduledDate = state.scheduledTime
        return model
    }

    func getModelFromMessageState(_ state: UserMessageState) -> DashboardViewModel {
        let model = DashboardViewModel()
        model.skill = state.skill
        model.user = state.user
        model.scheduledDate = state.scheduledTime
        return model
    }
}
