//
//  ViewController.swift
//  GalleryTest
//
//  Created by Sergey on 20.02.17.
//  Copyright © 2017 Sergey Kim. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    fileprivate var zoomHandler = ZoomableDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.zoomHandler.setup(withController: self)
        self.zoomHandler.delegate = self
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        
        cell.imageView.image = UIImage(named: "Image")
        cell.titleLabel.text = "\(indexPath.item)"
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 200)
    }
}

extension ViewController: ZoomableDelegate {
    
    func zoomableObject(forGestureRecognizer gestureRecognizer: UIPinchGestureRecognizer) -> ZoomableObject? {
        let touchLocation = gestureRecognizer.location(in: self.collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: touchLocation),
            let cell = self.collectionView.cellForItem(at: indexPath) as? ZoomableObject else {
                return nil
        }
        
        return cell 
    }
    
    func pinchStateChange(state: ZoomState) {
        switch state {
        case .began:
            self.collectionView.isScrollEnabled = false
        case .progress:
            break
        case .ended:
            self.collectionView.isScrollEnabled = true
        }
    }
    
    func pinchRecognizerShouldBegin(gestureRecognizer: UIPinchGestureRecognizer) -> Bool {
        let touch = gestureRecognizer.location(in: self.collectionView)
        if let _ = self.collectionView.indexPathForItem(at: touch) {
            return true
        }
        
        return false
    }
}
