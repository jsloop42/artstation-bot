//
//  Utils.swift
//  ArtStationBot
//
//  Created by jsloop on 20/07/19.
//

import Foundation

@objc
@objcMembers
class Utils: NSObject {
    private static var mozillaUserAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:67.0) Gecko/20100101 Firefox/67.0",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0"]
    private static var chromeUserAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36"]
    private static var safariUserAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.28 (KHTML, like Gecko) Version/11.0 Safari/604.1.28"]

    private override init() {}

    /// Returns a random user agent string
    static func getRandomUserAgent() -> String {
        let collRand = Int.random(in: 0...2)
        switch collRand {
        case 0:
            return self.safariUserAgents.randomElement() ?? safariUserAgents[0]
        case 1:
            return self.chromeUserAgents.randomElement() ?? chromeUserAgents[0]
        case 2:
            return self.mozillaUserAgents.randomElement() ?? mozillaUserAgents[0]
        default:
            return self.safariUserAgents[0]
        }
    }

    static func bundle() -> Bundle {
        return Bundle(for: self)
    }

    static func getConfig() -> NSDictionary? {
        let bundle = self.bundle()
        if let path = bundle.path(forResource: "config", ofType: "plist"), let conf = NSDictionary(contentsOfFile: path) {
            return conf
        }
        return nil
    }

    static func getFoundationDBClusterConfigPath() -> String {
        if let conf = getConfig(), let fdbconf = conf.value(forKey: "FoundationDB") as? NSDictionary {
            return fdbconf.value(forKey: "ClusterConfigPath") as? String ?? ""
        }
        return ""
    }
}
