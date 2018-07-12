//
//  FadeOutAnimationController.swift
//  StoreSearch
//
//  Created by Piercing on 29/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

/// La animación real, simplemente establece el punto de vista de alfa al valor 0 con el fin de desvanecer.
class FadeOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { return 0.4 }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) {
            
            let duration = transitionDuration(using: transitionContext)
            
            UIView.animate(withDuration: duration, animations: { fromView.alpha = 0 }, completion: {
                
                            finished in
                            transitionContext.completeTransition(finished)
            })
        }
    }
}
