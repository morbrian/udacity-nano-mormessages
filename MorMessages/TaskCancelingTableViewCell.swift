//
//  TaskCancelingTableViewCell.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class TaskCancelingTableViewCell : UITableViewCell {
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}