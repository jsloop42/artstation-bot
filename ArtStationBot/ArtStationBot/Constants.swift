//
//  Constants.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//  Copyright © 2019 DreamLisp. All rights reserved.
//

import Foundation

typealias Const = Constants

class Constants {
    struct URL {
        static let seed = "https://artstation.com/"
        static let csrf = "\(Const.URL.seed)api/v2/csrf_protection/token.json"
    }
}

struct ContentType {
    static let json = "application/json"
}
