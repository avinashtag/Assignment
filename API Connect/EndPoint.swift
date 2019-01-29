//
//  EndPoint.swift
//  ATCache
//
//  Created by Avinash Tag on 26/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import Foundation

protocol Endpoint {
    var base: String { get }
    var path: String { get }
    var queryParams: [URLQueryItem] { get set }
}

extension Endpoint {
    
    var urlComponents: URLComponents {
        var components = URLComponents(string: base)!
        components.path = path
        if !queryParams.isEmpty {
            components.queryItems = queryParams
        }
        return components
    }
    
    var urlRequest: URLRequest {
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        let headers = request.allHTTPHeaderFields ?? [:]
        request.allHTTPHeaderFields = headers
        return request
    }
    var hosname: String {
        return base
    }

}

enum Calls {
    case midValley
}

struct Constants {
   
    static let POST = "POST"
    static let GET = "GET"
    static let CONTENT_TYPE = "Content-Type"
    static let AUTHENTICATION_CONTENT_TYPE = "application/x-www-form-urlencoded"
    static let CONTENT_TYPE_VALUE = "application/json"
}

extension Calls: Endpoint {
    
    struct Keeper {
        static var _queryParams:[URLQueryItem] = [URLQueryItem]()
    }
    
    var queryParams: [URLQueryItem] {
        get {
            return Keeper._queryParams
        }
        set (newValue) {
            Keeper._queryParams = newValue
        }
    }
    
    var base: String {
        return "http://pastebin.com"
    }

    var path: String {
        switch self {

        case .midValley:
            return "/raw/wgkJgazE"
        }
    }
}
