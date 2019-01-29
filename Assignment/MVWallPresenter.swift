//
//  MVWallPresenter.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

protocol MVWallPresentationLogic
{
    func presentWall(result: APIResult<[MVWall.Response]?, APIError>)
}

class MVWallPresenter: MVWallPresentationLogic
{
    weak var viewController: MVWallDisplayLogic?
    
    // MARK: Do something
    
    func presentWall(result: APIResult<[MVWall.Response]?, APIError>)
    {
        switch result {
        case .success(let response):
            var model = MVWall.Presentation()
            model.data = response
            DispatchQueue.main.async {
                self.viewController?.displayWall(model: model)
            }
            break
            
        case .failure(let error):
            print("\(error.localizedDescription)")
            break
            
        }
    }
}
