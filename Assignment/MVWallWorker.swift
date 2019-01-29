//
//  MVWallWorker.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

class MVWallWorker : MVApiClient
{
    func fetchWall(completion: @escaping (APIResult<[MVWall.Response]?, APIError>) -> Void) {
      
        let endpoint = Calls.midValley
        var urlRequest = endpoint.urlRequest
        urlRequest.httpMethod = Constants.GET
        urlRequest.setValue(Constants.CONTENT_TYPE_VALUE, forHTTPHeaderField:Constants.CONTENT_TYPE)
        fetch(with: urlRequest, decode: { json -> [MVWall.Response]? in
            guard let result = json as? [MVWall.Response] else { return  nil }
            return result
        }, completion: completion)
    }

}
