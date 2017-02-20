//
//  ViewController.swift
//  GalleryTest
//
//  Created by Sergey on 20.02.17.
//  Copyright © 2017 Sergey Kim. All rights reserved.
//

import UIKit

enum ZoomState {
    case began
    case progress
    case ended
}

extension UIGestureRecognizer {
    func cancel() {
        self.isEnabled = false
        self.isEnabled = true
    }
}

extension UIViewController {
    func cancellAllGestures() {
        guard let gestureRecognizers = self.view.gestureRecognizers else {
            return
        }
        
        for gesture in gestureRecognizers {
            gesture.cancel()
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var curtainView: UIView!
    private var zoomableImageView = UIImageView()
    
    private var pinchZoomGesture: UIPinchGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var originCenter = CGPoint.zero
        
    fileprivate var state: ZoomState = .began {
        didSet {
            switch state {
            case .began:
                self.curtainView.isUserInteractionEnabled = true
                self.collectionView.isScrollEnabled = false
            case .progress:
                break
            case .ended:
                self.curtainView.isUserInteractionEnabled = false
                self.collectionView.isScrollEnabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pinchZoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture))
        self.pinchZoomGesture.delegate = self
        self.view.addGestureRecognizer(self.pinchZoomGesture)
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        self.panGesture.delegate = self
        self.view.addGestureRecognizer(self.panGesture)
        
        self.curtainView.isUserInteractionEnabled = false
    }

    dynamic func handlePinchGesture() {
        
        switch pinchZoomGesture.state {
        case .began:
            self.state = .began
            
            let touchLocation = pinchZoomGesture.location(in: self.collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchLocation),
                let cell = collectionView.cellForItem(at: indexPath) as? Cell {
                
                let initialFrame = self.curtainView.convert(cell.imageView.frame, from: cell)
                
                self.zoomableImageView.translatesAutoresizingMaskIntoConstraints = true
                self.zoomableImageView.frame = initialFrame
                self.originCenter = self.zoomableImageView.center
                self.zoomableImageView.image = UIImage(named: "Image")
                self.curtainView.addSubview(self.zoomableImageView)
            }
            else {
                self.cancellAllGestures()
            }
        case .changed:
            self.state = .progress
            
            let transform = self.zoomableImageView.transform.scaledBy(x: pinchZoomGesture.scale, y: pinchZoomGesture.scale)
            self.zoomableImageView.transform = transform
            pinchZoomGesture.scale = 1
            
        default:
            if self.state != .ended {
                endGestureAction()
            }
            self.state = .ended
        }
    }
    
    dynamic func handlePanGesture() {
        switch panGesture.state {
        case .began:
            break
        case .changed:
            let translation = panGesture.translation(in: self.view)
            let view = self.zoomableImageView
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
            
            panGesture.setTranslation(CGPoint.zero, in: self.view)
            
        default:
            if self.state != .ended {
                endGestureAction()
            }
            self.state = .ended
        }
    }
    
    private func endGestureAction() {
        UIView.animate(withDuration: 0.4, animations: {
            self.zoomableImageView.transform = CGAffineTransform.identity
            self.zoomableImageView.center = self.originCenter
        }, completion: { finished in
            self.zoomableImageView.removeFromSuperview()
        })
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer {
            let touch = gestureRecognizer.location(in: self.collectionView)
            if let _ = collectionView.indexPathForItem(at: touch) {
                return true
            }
            
            return false
        }
        
        return self.state == .began || self.state == .progress
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
