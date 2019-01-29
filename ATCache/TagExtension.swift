//
//  TagExtension.swift
//  ATCache
//
//  Created by Avinash Tag on 26/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import Foundation
import UIKit

public protocol ProtocolURL {
    var toUrl: URL? { get }
}
extension URL: ProtocolURL {
    public var toUrl: URL? { return self }
}
extension String: ProtocolURL {
    public var toUrl: URL? { return URL(string: self) }
}

fileprivate var handlerKey = "handler"
public class ViewHandler: NSObject {
    private var downloadIdentifiers = Set<String>()
    
    func cancel() {
        for identifier in downloadIdentifiers {
            Tag.sharedInstance.cancelDownload(identifier: identifier)
        }
        downloadIdentifiers.removeAll()
    }
    
    func invalidate() {
        for identifier in downloadIdentifiers {
            Tag.sharedInstance.invalidateDownload(identifier: identifier)
        }
        downloadIdentifiers.removeAll()
    }
    
    func load(url: URL?, cacheType: CacheType, requestModification: ((_ request: URLRequest) -> URLRequest)?, completion: ((_ result: ImageCompletion) -> ())?) {
        
        if let url = url {
            let identifier = UUID().uuidString
            downloadIdentifiers.insert(identifier)
            Tag.sharedInstance.retrieveImage(fromUrl: url, cacheType: cacheType, requestModification: nil, customIdentifier: identifier, completion: { [weak self] result in
                if self?.downloadIdentifiers.contains(identifier) ?? false {
                    let _ = self?.downloadIdentifiers.remove(identifier)
                    completion?(result)
                } else {
                    completion?(.canceledOrInvalidated)
                }
            })
        }
    }
}

extension UIImageView {
    public var handler: ViewHandler {
        if let obj = objc_getAssociatedObject(self, &handlerKey) as? ViewHandler {
            return obj
        } else {
            let obj = ViewHandler()
            objc_setAssociatedObject(self, &handlerKey, obj, .OBJC_ASSOCIATION_RETAIN)
            return obj
        }
    }
    
    public func cancelImageDownload() {
        handler.cancel()
    }
    
    public func invalidateImageDownload() {
        handler.invalidate()
    }
    
    public func setImage(withUrl url: ProtocolURL, placeholder: UIImage? = nil, cacheType: CacheType = .automatic, requestModification: ((_ request: URLRequest) -> URLRequest)? = nil, completion: ((_ result: ImageCompletion) -> ())? = nil) {
        
        var loaded = false
        
        if let placeholder = placeholder {
            image = placeholder
        } else {
            image = nil
            
            handler.load(url: url.toUrl, cacheType: .fromCache, requestModification: requestModification, completion: { [weak self] result in
                if case .image(let image, _) = result {
                    if !loaded {
                        self?.image = image
                    }
                }
            })
        }
        
        handler.load(url: url.toUrl, cacheType: cacheType, requestModification: requestModification) { [weak self] result in
            if case .image(let image, _) = result {
                loaded = true
                self?.image = image
            }
            completion?(result)
        }
    }
}


