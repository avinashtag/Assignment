//
//  MVWallInteractor.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

protocol MVWallBusinessLogic
{
  func fetchWall(request: MVWall.Request)
}

protocol MVWallDataStore
{
  //var name: String { get set }
}

class MVWallInteractor: MVWallBusinessLogic, MVWallDataStore
{
  var presenter: MVWallPresentationLogic?
  var worker: MVWallWorker?
  
  // MARK: Do something
  
    func fetchWall(request: MVWall.Request)  {
        worker = MVWallWorker()
        worker?.fetchWall(completion: { (result) in
           
            self.presenter?.presentWall(result: result)
        })
    }
    
}
