//
//  MVWallModels.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

enum MVWall
{

    struct Result: Codable {
        var data: [Response]?
    }
    struct Response: Codable
    {
        var id: String?
        var width: Int64?
        var height: Int64?
        var urls: Url?
    }
    
    struct Url: Codable {
        var full: String?
        var raw: String?
        var regular: String?
        var small: String?
        var thumb: String?

    }
    struct Request: Codable {

    }

    struct Presentation: Codable {
        var data : [Response]?
        
    }

}
