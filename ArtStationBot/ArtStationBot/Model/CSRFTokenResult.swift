//
//  CSRFTokenResult.swift
//  ArtStationBot
//
//  Created by jsloop on 21/07/19.
//

import Foundation

class CSRFTokenResult: Codable {
    var csrfToken: String

    init(csrfToken: String) {
        self.csrfToken = csrfToken
    }

    private enum CodingKeys: String, CodingKey {
        case csrfToken = "public_csrf_token"
    }
}
