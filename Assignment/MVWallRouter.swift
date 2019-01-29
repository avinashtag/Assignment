//
//  MVWallRouter.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

@objc protocol MVWallRoutingLogic
{
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol MVWallDataPassing
{
  var dataStore: MVWallDataStore? { get }
}

class MVWallRouter: NSObject, MVWallRoutingLogic, MVWallDataPassing
{
  weak var viewController: MVWallViewController?
  var dataStore: MVWallDataStore?
  
  // MARK: Routing
  
  //func routeToSomewhere(segue: UIStoryboardSegue?)
  //{
  //  if let segue = segue {
  //    let destinationVC = segue.destination as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //  } else {
  //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
  //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //    navigateToSomewhere(source: viewController!, destination: destinationVC)
  //  }
  //}

  // MARK: Navigation
  
  //func navigateToSomewhere(source: MVWallViewController, destination: SomewhereViewController)
  //{
  //  source.show(destination, sender: nil)
  //}
  
  // MARK: Passing data
  
  //func passDataToSomewhere(source: MVWallDataStore, destination: inout SomewhereDataStore)
  //{
  //  destination.name = source.name
  //}
}
