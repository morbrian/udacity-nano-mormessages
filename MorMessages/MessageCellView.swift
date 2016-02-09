//
//  MessageCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageCellView: TaskCancelingTableViewCell {

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
    
    
    
}