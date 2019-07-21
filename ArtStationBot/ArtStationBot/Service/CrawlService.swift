//
//  CrawlService.swift
//  ArtStationBot
//
//  Created by jsloop on 21/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation
import DLLogger

class CrawlService {
    private lazy var nwService = { return NetworkService(withQueue: .background) }()
    private let log = Logger()
    private var csrfToken: String = ""

    /// Retrieves a CSRF token that can be used for a new request.
    func getCSRFToken() {
        self.nwService.post(url: Const.URL.csrf, body: nil) { data, resp, err in
            do {
                guard let data = data else { return }
                let token = try JSONDecoder().decode(CSRFTokenResult.self, from: data)
                self.log.debug("post response: \(String(describing: resp))")
                self.log.debug("post error: \(String(describing: err))")
                self.log.debug("csrf token: \(token.csrfToken)")
                self.csrfToken = token.csrfToken
            } catch let err {
                self.log.error("Error decoding response: \(err)")
            }
        }
    }
}
