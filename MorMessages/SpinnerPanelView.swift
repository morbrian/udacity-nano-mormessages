//
//  SpinnerPanelView.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// SpinnerPanelView
// custom view supports spinning an imageView for use during network activity
class SpinnerPanelView: UIView {
    
    let SpinnerSize = CGFloat(44.0)
    
    var spinnerImageView: UIImageView!
    var activityInProgress = false
    private var spinnerBaseTransform: CGAffineTransform!
    
    init(frame: CGRect, spinnerImageView: UIImageView) {
        super.init(frame: frame)
        self.spinnerImageView = spinnerImageView
        self.hidden = !activityInProgress
        self.spinnerBaseTransform = spinnerImageView.transform
        self.addSubview(spinnerImageView)
        spinnerImageView.contentMode = UIViewContentMode.ScaleAspectFit
        spinnerImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(
            item: spinnerImageView,
            attribute: NSLayoutAttribute.Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: SpinnerSize))
        self.addConstraint(NSLayoutConstraint(
            item: spinnerImageView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: SpinnerSize))
        
        self.addConstraint(NSLayoutConstraint(
            item: spinnerImageView,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1.0,
            constant: 0.0))
        self.addConstraint(NSLayoutConstraint(
            item: spinnerImageView,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1.0,
            constant: 0.0))
    }
    
    required init(coder aDecoder: NSCoder) {
        // we don't support this, it should never be called
        fatalError("init(coder:) has not been implemented")
    }
    
    // when active = true kicks off the spinner until called again with active = false
    func spinnerActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityInProgress = active
            self.hidden = !active
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
            
            Logger.info("Panel Center = \(self.center)")
            Logger.info("Image Center = \(self.spinnerImageView.center)")
            if (active) {
                self.animate()
            }
        }
    }
    
    // continue to animate the spinner until spinnerActivity is not active
    func animate() {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.001,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { self.spinnerImageView.transform =
                    CGAffineTransformConcat(self.spinnerImageView.transform, CGAffineTransformMakeRotation((CGFloat(60.0) * CGFloat(M_PI)) / CGFloat(180.0)) )},
                completion: { something in
                    if self.activityInProgress {
                        self.animate()
                    } else {
                        // TODO: this snaps to position at then end, we should perform the final animation.
                        self.spinnerImageView.transform = self.spinnerBaseTransform
                    }
            })
        }
    }
}
