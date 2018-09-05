//
//  DraggableView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/4/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

public class DraggableView: UILabel, UIGestureRecognizerDelegate {
    var maxScale: CGFloat = 5
    var minScale: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame);
        setupRecognizers()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupRecognizers()
    }

    // MARK: Gestures

    var identity = CGAffineTransform.identity
    var lastLocation = CGPoint()
    var pinchGesture: UIPinchGestureRecognizer!
    var rotationGesture: UIRotationGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!

    public func setupRecognizers() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.didPinch(_:)))
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.didRotate(_:)))

        panGesture.delegate = self
        pinchGesture.delegate = self
        rotationGesture.delegate = self

        //Enable multiple touch and user interaction for textfield
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true

        self.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(pinchGesture)
        self.addGestureRecognizer(rotationGesture)
    }

    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let translation = gesture.translation(in: self.superview!)

            self.lastLocation = self.center
            self.center = CGPoint(x: self.center.x + translation.x,
                                  y: self.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: self)
        }
    }

    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        let scale = self.transform.scaledBy(x: gesture.scale, y: gesture.scale).getScale()
        guard scale > self.minScale && scale < self.maxScale else { return }
        
        self.transform = self.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
    }

    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        self.transform = self.transform.rotated(by: gesture.rotation)
        // Set to zero after every rotation so the rotation follows users fingers
        gesture.rotation = 0
    }

    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.superview?.bringSubview(toFront: self)
    }
}

extension CGAffineTransform {
    func getScale() -> CGFloat {
        return CGFloat(sqrt(Double(self.a * self.a + self.c * self.c)))
    }
}
