//
//  MessageCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageCellView: UICollectionViewCell {
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }

    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            if contentTextView != nil {
                contentTextView.layer.cornerRadius = 8.0
            }
        }
    }
    
    var message: Message? {
        didSet {
            if let message = message {
                configureCellWithMessage(message)
            } else {
                contentTextView.text = nil
            }
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCellWithMessage(message: Message) {
        
        if let contentTextView = contentTextView {
            contentTextView.text = message.text
        }
    }
    
    //
    // with help from:
    // http://stackoverflow.com/questions/25895311/uicollectionview-self-sizing-cells-with-auto-layout
    //
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let superAttributes = super.preferredLayoutAttributesFittingAttributes(layoutAttributes)
        if let attr: UICollectionViewLayoutAttributes = superAttributes.copy() as? UICollectionViewLayoutAttributes {
            var newFrame = attr.frame
            self.frame = newFrame
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
            
            let desiredHeight: CGFloat = self.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            newFrame.size.height = desiredHeight
            attr.frame = newFrame
            
            return attr
        } else {
            Logger.error("Failed to calculate preferred layout because we don't know the attribute type")
            return superAttributes
        }
    }
    
}