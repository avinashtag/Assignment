//
//  MVWallViewController.swift
//  Assignment
//
//  Created by Avinash Tag on 28/01/2019.
//  Copyright (c) 2019 Avinash Tag. All rights reserved.
//

import UIKit

protocol MVWallDisplayLogic: class
{
  func displayWall(model: MVWall.Presentation)
}

class MVWallViewController: UIViewController, MVWallDisplayLogic
{
    
    @IBOutlet weak var collection: UICollectionView!
    
    var interactor: MVWallBusinessLogic?
    var router: (NSObjectProtocol & MVWallRoutingLogic & MVWallDataPassing)?
    var refreshControl : UIRefreshControl?
    
    var datasource : MVWall.Presentation?
    
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup()
    {
        let viewController = self
        let interactor = MVWallInteractor()
        let presenter = MVWallPresenter()
        let router = MVWallRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(doRefresh), for: .valueChanged)
        collection.addSubview(refreshControl!)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadWall()
    }
    
    
    private func loadWall(){
        let request = MVWall.Request()
        interactor?.fetchWall(request: request)
    }
    
    
    func displayWall(model: MVWall.Presentation)
    {
        //nameTextField.text = viewModel.name
        datasource = model
        self.collection.reloadData()
        refreshControl?.endRefreshing()
    }
    
    @objc func doRefresh () {

        refreshControl?.beginRefreshing()
        loadWall()
    }

}

extension MVWallViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource?.data?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCellIdentifier", for: indexPath) as? MVWallCell else {return UICollectionViewCell()}
        
        let data = datasource?.data?[indexPath.row]
        if let imageUrl = data?.urls?.small{
            print("\(imageUrl)")
            cell.image.setImage(withUrl: imageUrl, placeholder: nil, cacheType: .automatic, requestModification: nil) { (completion) in
                
            }
        }
        
        

        return cell
    }
    
    
}

extension MVWallViewController: UICollectionViewDelegate{
    
}

extension MVWallViewController: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellWidth = (self.collection.frame.size.width - 15) / 2
        
        if let data = datasource?.data?[indexPath.row]{
            
            let calHeight = (CGFloat(data.height ?? 0) / CGFloat(data.width ?? 1)) * cellWidth
            return CGSize(width: cellWidth, height: calHeight)
        }
        return CGSize(width: cellWidth, height: cellWidth)
        
    }
}

