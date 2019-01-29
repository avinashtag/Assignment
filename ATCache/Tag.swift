//
//  Tag.swift
//  ATCache
//
//  Created by Avinash Tag on 26/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import Foundation
import UIKit


public enum DownloadCompletion {
    case canceled
    case error(error: NSError)
    case success(image: UIImage, data: Data)
}

public enum ImageCompletion {
    case canceledOrInvalidated
    case error(error: NSError)
    case image(image: UIImage, data: Data)
}

@objc public enum CacheType: Int {
    case automatic
    case forceCache
    case forceDownload
    case `protocol`
    case fromCache
}

public class Tag {
    
    
    static let domain = "Tag"

    public static let sharedInstance = Tag(identifier: "tag")
    
    
    public var timeoutInterval = 30.0
    public var cacheStaleInterval = 30.0
    
    private let operationQueue = OperationQueue()
    public let cache: ATCache
    
    private lazy var keyCache: NSCache<NSString, NSString> = {
        var cache = NSCache<NSString, NSString>()
        cache.countLimit = 512
        return cache
    }()
    
    private var requestHeaders = Headers()
    private var credentials = Credentials()
    private var trustsAllCertificates = false
    
    public init(identifier: String) {
        cache = try! ATCache(name: identifier)
    }
    
    // MARK: - Public methods
    @discardableResult
    public func downloadImage(fromUrl url: URL, cachePolicy: NSURLRequest.CachePolicy, requestModification: ((_ request: URLRequest) -> URLRequest)? = nil, customIdentifier: String? = nil, completion: ((_ result: DownloadCompletion, _ invalidated: Bool) -> ())?) -> String {
        
        let identifier: String = customIdentifier ?? UUID().uuidString
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        
        // set headers
        request.addValue("image/*, */*; q=0.5", forHTTPHeaderField: "Accept")
        for (key, value) in requestHeaders.headersForHost(url.host) {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if let closure = requestModification {
            request = closure(request)
        }
        
        let operation = TagOperation(urlRequest: request, identifier: identifier, callbackQueue: DispatchQueue.main, downloadFinishedBlock: { operation, result in
            
            switch result {
            case .canceled:
                completion?(.canceled, operation.invalidated)
            case .error(let error):
                completion?(.error(error: error as NSError), operation.invalidated)
            case .success(let image, let data):
                completion?(.success(image: image, data: data), operation.invalidated)
            }
        })
        
        // configure operation
        if let credentials = credentials.credentialsForHost(url.host) {
            operation.credentials  = credentials
        }
        operation.trustsAllCertificates = trustsAllCertificates
        
        operationQueue.addOperation(operation)
        
        return identifier
    }
    
    public func retrieveImage(fromUrl url: URL, cacheType: CacheType, requestModification: ((_ request: URLRequest) -> URLRequest)? = nil, customIdentifier: String? = nil, completion: ((_ result: ImageCompletion) -> ())?) {
        let cacheKey = transformUrlToCacheKey(url)
        
        let downloadAction = { (cachePolicy: NSURLRequest.CachePolicy) -> Void in
            self.downloadImage(fromUrl: url, cachePolicy: cachePolicy, requestModification: requestModification, customIdentifier: customIdentifier, completion: { completionType, invalidated in
                
                if invalidated {
                    completion?(.canceledOrInvalidated)
                } else {
                    switch completionType {
                    case .canceled:
                        completion?(.canceledOrInvalidated)
                    case .error(let error):
                        completion?(.error(error: error))
                    case .success(let image, let data):
                        self.cache.store(data: data, forKey: cacheKey, image: image, callbackQueue: DispatchQueue.main, completion: {
                            completion?(.image(image: image, data: data))
                        })
                    }
                }
            })
        }
        
        switch cacheType {
        case .forceDownload:
            downloadAction(.reloadIgnoringLocalCacheData)
        case .protocol:
            downloadAction(.useProtocolCachePolicy)
        default:
            cache.fetch(itemWithKey: cacheKey) { item in
                if let item = item {
                    if cacheType == .fromCache || cacheType == .forceCache || Date().timeIntervalSince(item.created) < self.cacheStaleInterval {
                        completion?(.image(image: item.image, data: item.data))
                    } else {
                        downloadAction(.useProtocolCachePolicy)
                    }
                } else {
                    if cacheType == .fromCache {
                        completion?(.canceledOrInvalidated)
                    } else {
                        downloadAction(.useProtocolCachePolicy)
                    }
                }
            }
        }
    }
    
    public func cancelDownload(identifier: String?) {
        guard let identifier = identifier else { return }
        
        for operation in operationQueue.operations {
            if let operation = operation as? TagOperation, operation.identifier == identifier {
                operation.cancel()
            }
        }
    }
    
    public func invalidateDownload(identifier: String?) {
        guard let identifier = identifier else { return }
        
        for operation in operationQueue.operations {
            if let operation = operation as? TagOperation, operation.identifier == identifier {
                operation.invalidated = true
            }
        }
    }
    
    public func setHeaderValue(_ value: String?, forHeaderWithName name: String, forHost host: String? = nil) {
        requestHeaders.setHeader(name, value: value, forHost: host)
    }
    
    public func setGlobalBasicAuthCredentials(_ credentials: URLCredential?, forHost host: String? = nil) {
        self.credentials.setCredentials(credentials, forHost: host)
    }
    

    public func setGlobalBasicAuthCredentials(user: String?, password: String?, forHost host: String? = nil) {
        if let user = user, let password = password {
            credentials.setCredentials(URLCredential(user: user, password: password, persistence: .none), forHost: host)
        } else {
            credentials.setCredentials(nil, forHost: host)
        }
    }
    
    public func trustAllCertificates() {
        trustsAllCertificates = true
    }
    
    private func transformUrlToCacheKey(_ url: URL) -> String {
        let urlString = url.absoluteString
        
        if let key = keyCache.object(forKey: urlString as NSString) as String? {
            return key
        } else {
            if let data = urlString.data(using: .utf8) {
                return data.base64EncodedString()
            } else {
                return ""
            }
        }
    }
}

private class Headers {
    private var allHostsHeaders = [String: String]()
    private var specificHostHeaders = [String: [String: String]]()
    
    func setHeader(_ name: String, value: String?, forHost host: String?) {
        if let host = host {
            var headers = specificHostHeaders[host] ?? [String: String]()
            headers[name] = value
            specificHostHeaders[host] = headers
        } else {
            allHostsHeaders[name] = value
        }
    }
    
    func setHeaders(_ headers: [String: String], forHost host: String?) {
        if let host = host {
            specificHostHeaders[host] = headers
        } else {
            allHostsHeaders = headers
        }
    }
    
    func headersForHost(_ host: String?) -> [String: String] {
        if let host = host {
            if let specificHeaders = specificHostHeaders[host] {
                return specificHeaders.reduce(allHostsHeaders) { (dict, e) in
                    var mutableDict = dict
                    mutableDict[e.0] = e.1
                    return mutableDict
                }
            } else {
                return allHostsHeaders
            }
        } else {
            return allHostsHeaders
        }
    }
}

private class Credentials {
    
    
    
    private var allHostsCredentials: URLCredential?
    private var specificHostCredentials = [String: URLCredential]()
    
    func setCredentials(_ credentials: URLCredential?, forHost host: String?) {
        if let host = host {
            specificHostCredentials[host] = credentials
        } else {
            allHostsCredentials = credentials
        }
    }
    
    func credentialsForHost(_ host: String?) -> URLCredential? {
        if let host = host {
            if let specificCredentials = specificHostCredentials[host] {
                return specificCredentials
            } else {
                return allHostsCredentials
            }
        } else {
            return allHostsCredentials
        }
    }
}

// MARK: - Data Extension
fileprivate extension Data {
    var hexString: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}
