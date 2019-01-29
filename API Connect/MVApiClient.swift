//
//  MVApiClient.swift
//  ATCache
//
//  Created by Avinash Tag on 27/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import UIKit

class MVApiClient: APIClient {

    static let sharedInstance = MVApiClient(configuration: .default)
    
    let session: URLSession
    
    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
        self.session.configuration.requestCachePolicy = .useProtocolCachePolicy
    }
    
    convenience init() {
        self.init(configuration: .default)
    }

}
