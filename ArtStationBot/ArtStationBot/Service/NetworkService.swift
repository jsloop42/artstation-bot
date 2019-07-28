//
//  NetworkService.swift
//  ArtStationBot
//
//  Created by jsloop on 21/07/19.
//

import Foundation
import SystemConfiguration
import DLLogger

class NetworkService: NSObject {
    private let log = Logger()
    private lazy var backgroundQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "Network Service Background Queue"
        q.qualityOfService = QualityOfService.background
        return q
    }()
    private lazy var userInitiatedQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "Network Service User Initiated Queue"
        q.qualityOfService = QualityOfService.userInitiated
        return q
    }()
    private lazy var bgSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: self.backgroundQueue)
        session.sessionDescription = "Network service background session"
        return session
    }()
    private lazy var usrSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: self.userInitiatedQueue)
        session.sessionDescription = "Network service user initiated session"
        return session
    }()
    private let userAgent = Utils.getRandomUserAgent()
    private let requestedWith = "XMLHttpRequest"
    var queueType: QueueType = .background

    override init() {}

    init(withQueue queue: QueueType) {
        self.queueType = queue
    }

    /// Send a `GET` request using the given url components and invokes the callback on response.
    /// - Parameters:
    ///     - comp: The url component from which the url will be constructed.
    ///     - callback: A callback function to receive the response.
    func get(comp: URLComponents, callback: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        guard Reachability.isConnectedToNetwork() else { return callback(nil, nil, AppError.offline) }
        guard let url: URL = comp.url else { return callback(nil, nil, AppError.urlError) }
        (self.queueType == .background ? self.bgSession : self.usrSession).dataTask(with: url, completionHandler: callback).resume()
    }

    /// Send a `HTTP POST` request.
    /// - Parameters:
    ///     - url: The url of the `POST` request.
    ///     - body: The `POST` body.
    ///     - headers: An optional dictionary containing headers to be appended
    ///     - callback: The callback function.
    ///     - data: The data returned from the `POST` call.
    ///     - response: The `URLResponse` object.
    ///     - error: An optional error object.
    func post(url: String, body: Data? = nil, headers: [String: String]? = nil,
              callback: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        guard Reachability.isConnectedToNetwork() else { return callback(nil, nil, AppError.offline) }
        guard let url = URL(string: url) else { return callback(nil, nil, AppError.urlError) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue(ContentType.json, forHTTPHeaderField: "Content-Type")
        request.addValue(ContentType.json, forHTTPHeaderField: "Accept")
        request.addValue(self.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(Const.URL.seed, forHTTPHeaderField: "Origin")
        request.addValue(self.requestedWith, forHTTPHeaderField: "x-requested-with")
        if let headersDict = headers, headersDict.count > 0 {
            headersDict.keys.forEach { key in
                if let val = headersDict[key] { request.addValue(val, forHTTPHeaderField: key) }
            }
        }
        (self.queueType == .background ? self.bgSession : self.usrSession).dataTask(with: request, completionHandler: callback).resume()
    }
}

extension NetworkService {
    enum QueueType {
        case background
        case userInitiated
    }
}

/// A class used to check if internet connectivity is present.
public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}
