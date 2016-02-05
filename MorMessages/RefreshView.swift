//
//  RefreshView.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/15/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//
// This class is patterned after a tutorial on raywenderlich.com
// Reference: http://www.raywenderlich.com/93695/video-tutorial-swift-scroll-view-school-part-17-pull-refresh-iii
//

import UIKit

// RefreshView
// view displayed at top of tableview during network activity
class RefreshView: UIView {
    private unowned var scrollView: UIScrollView
    weak var delegate: RefreshViewDelegate?
    
    private var isRefreshing = false
    private var spinnerAreaHeight: CGFloat
    
    var progressPercentage: CGFloat = 0
    
    var refreshItem: RefreshItem!
    
    required init?(coder: NSCoder) {
        scrollView = UIScrollView()
        spinnerAreaHeight = CGFloat(44)
        assert(false, "use init(frame: scrollView:)")
        super.init(coder: coder)
    }
    
    init(frame: CGRect, spinnerAreaHeight: CGFloat, scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.spinnerAreaHeight = spinnerAreaHeight
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = Constants.ThemeStrongColor
        
        let themeImageView = UIImageView(image: UIImage(named: Constants.MorMessagesInverseImage))
        themeImageView.contentMode = UIViewContentMode.ScaleAspectFit
        let scaleFactor = spinnerAreaHeight / themeImageView.bounds.height
        themeImageView.transform =
            CGAffineTransformMakeScale(scaleFactor, scaleFactor)
        let viewCenter = CGPoint(x: bounds.size.width / 2, y: bounds.size.height - spinnerAreaHeight / 2)
        themeImageView.sizeToFit()
        self.refreshItem = RefreshItem(view: themeImageView, center: viewCenter)
        addSubview(refreshItem.view)
    }
    
    func beginRefreshing() {
        isRefreshing = true
        refreshItem.activityInProgress = true
        refreshItem.animate()
        UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.scrollView.contentInset.top += self.spinnerAreaHeight
            }, completion: { (_) -> Void in
        })
    }
    
    func endRefreshing() {
        dispatch_async(dispatch_get_main_queue()) {
            self.refreshItem.activityInProgress = false
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                self.scrollView.contentInset.top -= self.spinnerAreaHeight
                }, completion: { (_) -> Void in
                    self.isRefreshing = false
            })
        }
    }
    
}

// MARK: - Protocol RefreshViewDelegate

protocol RefreshViewDelegate: class {
    func refreshViewDidRefresh(refreshView: RefreshView)
}

// MARK: - UIScrollViewDelegate

extension RefreshView: UIScrollViewDelegate {
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !isRefreshing && progressPercentage == 1 {
            beginRefreshing()
            targetContentOffset.memory.y = -scrollView.contentInset.top
            delegate?.refreshViewDidRefresh(self)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isRefreshing {
            return
        }
        
        let refreshViewVisibleHeight = max(0, -(scrollView.contentOffset.y + scrollView.contentInset.top))
        progressPercentage = min(1, refreshViewVisibleHeight / spinnerAreaHeight)
    }
}

