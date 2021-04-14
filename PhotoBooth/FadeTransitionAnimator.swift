//
//  FadeTransitionAnimator.swift
//  PhotoBooth
//
//  Created by Ben Jones on 10/27/14.
//  Copyright (c) 2014 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit

class FadeTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  var isDismiss: Bool = false
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.38
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    var toView: UIView?
    var fromView: UIView?
    
    if let view = transitionContext.view(forKey: UITransitionContextViewKey.to) {
      toView = view
    } else {
      toView = UIView()
    }
    
    if let view = transitionContext.view(forKey: UITransitionContextViewKey.from) {
      fromView = view
    } else {
      fromView = UIView()
    }
    
    toView?.alpha = isDismiss ? 1 : 0
    
    transitionContext.containerView.addSubview(fromView!)
    transitionContext.containerView.addSubview(toView!)
    
    toView?.tintAdjustmentMode = .dimmed
    fromView?.tintAdjustmentMode = .dimmed
    UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, options: .curveEaseOut, animations: {
      fromView?.alpha = 0
      
      toView?.alpha = 1
      toView?.tintAdjustmentMode = .automatic
    }) { finished in
      fromView?.alpha = 1
      fromView?.tintAdjustmentMode = .automatic
      
      let transitionCanceled = transitionContext.transitionWasCancelled
      transitionContext.completeTransition(!transitionCanceled)
    }
  }
}
