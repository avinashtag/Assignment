//
//  ATCache.swift
//  ATCache
//
//  Created by Avinash Tag on 26/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import UIKit


public enum ImageFormat {
    case png
    case jpeg(quality: CGFloat)
}

public class Cache {
    
    var lastUsed: Date
    let created: Date
    let data: Data
    let image: UIImage
    
    init(data: Data, image: UIImage?, created: Date? = nil) {

        self.lastUsed = Date()
        self.created = created ?? Date()

        self.data = data
        if let image = image {
            self.image = image
        } else {
            self.image = UIImage(data: data) ?? UIImage()
        }
    }
}


struct Settings {
    
    var cleanUpDays : Int = 10
    var size : Int = 32 * 1024 * 1024
}

public class ATCache {
   
    static let domain = "ATCache"
    
    private let memoryCache = NSCache<NSString, Cache>()
    private let url: URL
    private let cacheQueue = DispatchQueue(label: domain)
    private let autoCleanupDays: Int
    
    
    var setting : Settings = Settings()
    
    public init(name: String) throws {
       
        memoryCache.totalCostLimit = setting.size
        autoCleanupDays = setting.cleanUpDays

        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            throw NSError(domain: ATCache.domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Error while creating cache."])
        }
        
        url = URL(fileURLWithPath: cachesPath).appendingPathComponent("\(ATCache.domain)-\(name)")
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(cleanup), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    
    //******* Store Data in Cache
    //******* @parameters:
    // @data: The Data wish to store in cache
    // @key: The key to store data.
    // @image: Optional UIImage to store in cache.
    // @callbackQueue: DispatchQueue to call completion closure
    // @completion: completion closure after the data store successfully.
    //*********************************************************************
    
    public func store(data: Data, forKey key: String, image: UIImage? = nil, callbackQueue: DispatchQueue = DispatchQueue.main, completion: (() -> ())? = nil) {
        cacheQueue.async {
            let item = Cache(data: data, image: image)
            
            self.memoryCache.setObject(item, forKey: key as NSString, cost: data.count)
            
            let url = self.url.appendingPathComponent(key)
            
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                print(error)
            }
            
            callbackQueue.async {
                completion?()
            }
        }
    }
    
    //******* Removes data from cache.
    //******* @parameters:
    // @key: the key for which item wants to remove.
    // @callbackQueue: DispatchQueue to call completion closure
    // @completion: completion closure after the data store successfully.
    //*********************************************************************

    public func remove(itemWithKey key: String, callbackQueue: DispatchQueue = DispatchQueue.main, completion: (() -> ())?) {
        cacheQueue.async {
            self.memoryCache.removeObject(forKey: key as NSString)
            
            let url = self.url.appendingPathComponent(key)
            try? FileManager.default.removeItem(at: url)
            
            callbackQueue.async {
                completion?()
            }
        }
    }
    
    
    //******* fetch Data from Cache.
    //******* @parameters:
    // @key: the key to fetch Data.
    // @callbackQueue: DispatchQueue to call completion closure
    // @completion: completion closure after the data store successfully.
    //*********************************************************************

    public func fetch(itemWithKey key: String, callbackQueue: DispatchQueue = DispatchQueue.main, completion: @escaping (_ item: Cache?) -> ()) {
        cacheQueue.async {
            let url = self.url.appendingPathComponent(key)
            
            if let item = self.memoryCache.object(forKey: key as NSString) { // memory cache hit
                item.lastUsed = Date()
                callbackQueue.async {
                    completion(item)
                }
                
                try? (url as NSURL).setResourceValue(item.lastUsed, forKey: URLResourceKey.contentAccessDateKey)
            } else {
                do {
                    // try to load from disk cache
                    
                    // get file creation date
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let created = attributes[FileAttributeKey.creationDate] as? Date
                    
                    // load image data
                    let data = try Data(contentsOf: url)
                    
                    // create a new cache item
                    let item = Cache(data: data, image: UIImage(data: data), created: created)
                    
                    // update memory cache
                    self.memoryCache.setObject(item, forKey: key as NSString, cost: data.count)
                    
                    callbackQueue.async {
                        completion(item)
                    }
                    
                    try? (url as NSURL).setResourceValue(item.lastUsed, forKey: URLResourceKey.contentAccessDateKey)
                } catch { // cache miss
                    callbackQueue.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    //******* clean Cache .
    //*********************************************************************

    @objc private func cleanup() {
        if autoCleanupDays == 0 { return } // cleanup disabled
        
        cacheQueue.sync {
            memoryCache.removeAllObjects()
            
            do {
                let filesArray = try FileManager.default.contentsOfDirectory(atPath: url.path)
                let now = Date()
                for file in filesArray {
                    let url = self.url.appendingPathComponent(file)
                    var lastAccess: AnyObject?
                    do {
                        try (url as NSURL).getResourceValue(&lastAccess, forKey: URLResourceKey.contentAccessDateKey)
                        if let lastAccess = lastAccess as? Date {
                            if now.timeIntervalSince(lastAccess) > TimeInterval(autoCleanupDays * 24 * 3600) {
                                try FileManager.default.removeItem(at: url)
                            }
                        }
                    } catch {
                        continue
                    }
                    
                }
            } catch {}
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
    }
}
