//
//  UIView.swift
//  Skycast
//
//  Created by Kevin Kong on 3/5/16.
//  Copyright © 2016 Kevin Kong. All rights reserved.
//

import UIKit

extension UIView {
    
    // Fades
    
    func fadeIn(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: ((Bool) -> Void)? = {(finished: Bool) -> Void in}) {
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 1.0
            }, completion: completion)  }
    
    func fadeOut(duration: NSTimeInterval = 0.2, delay: NSTimeInterval = 0.0, completion: ((Bool) -> Void)? = {(finished: Bool) -> Void in}) {
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 0.0
            }, completion: completion)
    }
    
}