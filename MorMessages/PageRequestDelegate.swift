//
//  PageRequestProtocol.swift
//  MorMessages
//
//  Created by Brian Moriarty on 2/15/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation

protocol PageRequestDelegate {
    
    func pagedItems(offset offset: Int, resultSize: Int, greaterThan: NSDate,
                        completionHandler: (() -> Void)?)
    
}