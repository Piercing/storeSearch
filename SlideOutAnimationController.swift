//
//  SlideOutAnimationController.swift
//  StoreSearch
//
//  Created by Piercing on 27/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

// Esto  es más o menos el mismo que el otro  control de animación, excepto que la animación en sí es diferente. Dentro
// del bloque de animación se resta la altura de la pantalla desde la posición central de la vista y al mismo tiempo el
// zoom hacia fuera al --> 50% de su tamaño original, por lo que la pantalla Detalle volar hasta arriba de ida y vuelta.

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext:UIViewControllerContextTransitioning?) -> TimeInterval { return 0.6 }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) {
            
            let containerView = transitionContext.containerView
            let duration = transitionDuration(using: transitionContext)
            
            UIView.animate(withDuration: duration, animations: {
                fromView.center.y -= containerView.bounds.size.height
                fromView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: { finished in transitionContext.completeTransition(finished) } )
        }
    }
}
