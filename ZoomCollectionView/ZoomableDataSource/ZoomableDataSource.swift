//
//  ZoomableDataSource.swift
//  ZoomCollectionView
//
//  Created by Sergey Kim on 28.02.17.
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

protocol ZoomableObject {
    var imageView: UIImageView! {get set}
    var objectView: UIView {get}
}

protocol ZoomableDelegate: class {
    func pinchRecognizerShouldBegin(gestureRecognizer: UIPinchGestureRecognizer) -> Bool
    func pinchStateChange(state: ZoomState)
    func zoomableObject(forGestureRecognizer gestureRecognizer: UIPinchGestureRecognizer) -> ZoomableObject?
}

final class ZoomableDataSource: NSObject {
    
    fileprivate var parentController: UIViewController?
    
    private var curtainView: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.0)
        return view
    }()
    private var zoomableImageView = UIImageView()
    
    private var pinchZoomGesture: UIPinchGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var originCenter = CGPoint.zero
    
    weak var delegate: ZoomableDelegate?
    
    fileprivate var state: ZoomState = .began {
        didSet {
            self.delegate?.pinchStateChange(state: state)
            
            switch state {
            case .began:
                self.curtainView.isUserInteractionEnabled = true
                self.curtainView.backgroundColor = UIColor(white: 0, alpha: 0.3)
            case .progress:
                break
            case .ended:
                self.curtainView.isUserInteractionEnabled = false
                self.curtainView.backgroundColor = UIColor(white: 0, alpha: 0.0)
            }
        }
    }
    
    func setup(withController controller: UIViewController) {
        
        self.pinchZoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture))
        self.pinchZoomGesture.delegate = self
        controller.view.addGestureRecognizer(self.pinchZoomGesture)
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        self.panGesture.delegate = self
        controller.view.addGestureRecognizer(self.panGesture)
        
        controller.view.addSubview(self.curtainView)
        controller.view.bringSubview(toFront: self.curtainView)
        self.curtainView.frame = controller.view.bounds
        self.curtainView.isUserInteractionEnabled = false
        
        self.parentController = controller
    }
    
    dynamic func handlePinchGesture() {        
        switch pinchZoomGesture.state {
        case .began:
            self.state = .began
            
            if let zoomable = self.delegate?.zoomableObject(forGestureRecognizer: pinchZoomGesture) {                            
                let initialFrame = self.curtainView.convert(zoomable.imageView.frame, from: zoomable.objectView)
                
                self.zoomableImageView.contentMode = .scaleAspectFit
                self.zoomableImageView.translatesAutoresizingMaskIntoConstraints = true
                self.zoomableImageView.frame = initialFrame
                self.originCenter = self.zoomableImageView.center
                self.zoomableImageView.image = zoomable.imageView.image
                self.curtainView.addSubview(self.zoomableImageView)
            }
            else {
                self.parentController?.cancellAllGestures()
            }
        case .changed:
            self.state = .progress
            
            let transform = self.zoomableImageView.transform.scaledBy(x: pinchZoomGesture.scale, 
                                                                      y: pinchZoomGesture.scale)
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
            let translation = panGesture.translation(in: self.parentController?.view)
            let view = self.zoomableImageView
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
            
            panGesture.setTranslation(CGPoint.zero, in: self.parentController?.view)
            
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

extension ZoomableDataSource: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer,
            let delegate = self.delegate {
            return delegate.pinchRecognizerShouldBegin(gestureRecognizer: gestureRecognizer as! UIPinchGestureRecognizer)
        }
        
        return self.state == .began || self.state == .progress
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

