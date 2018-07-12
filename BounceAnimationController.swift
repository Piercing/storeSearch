//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by Piercing on 27/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

// Para convertirse en un control de animación, el objeto necesita extenderse de NSObject y de un protocolo UIViewControllerAnimatedTransitioning.
class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    
    // Esto determina el tiempo de la animación --> 0.4 segundos.
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { return 0.7 }
    
    // Se realiza la animación real.
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Averiguamos qué animamos, para ello nos fijamos en el parámetro "transitionContext". Éste le da una referencia al nuevo controlador de vista y le permite saber qué tan ---------
        // grande debe ser la animación. La animación se inicia con al vista reducida al 70% (0.7). El siguiente fotograma se infla al 120% (1.2) de su tamaño normal. Después, se escala la
        // vista un poco más, pero no tanto como antes (sólo el 90% de su tamaño ---> (0.9). El fotograma clave definitivo termina con una escala de 1.0 restaurando la vista sin distorsión.
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to), let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
            
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            toView.transform = CGAffineTransform(translationX: -10, y: 10)
            toView.transform = CGAffineTransform(rotationAngle: 180.0)
            
            
            // Aquí comienza la animación real, en "animateKeyframes". Se establece el estado inicial antes de que el bloque de animación, y UKit animen
            // automáticamente las propiedades que se cambian en el interior del cierre. La diferencia con el anterior es que una animación de fotogramas
            // clave le permite animar la vista en varias etapas distintas. Al cambiar rápidamente el tamaño de grande a pequeño se crea el efecto rebote.
            // También se debe especificar la duración entre los fotogramas sucesivos. En este caso, cada transición de un fotograma al siguiente toma 1/3
            // del tiempo total de la animación. Estos tiempos no son en un segundo, pero son fracciones de duración total de la animación, es decir, 0.4sg.
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.000, relativeDuration: 0.334, animations: {toView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) } )
                UIView.addKeyframe(withRelativeStartTime: 0.334, relativeDuration: 0.333, animations: {toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) } )
                UIView.addKeyframe(withRelativeStartTime: 0.666, relativeDuration: 0.333, animations: {toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) } ) },
                                    completion: {finished in transitionContext.completeTransition(finished) } )
        }
        
        // NOTA: Para que esta animación suceda le tenemos que decir a la aplicación el nuevo controlador de animación a utilizar
        // al presentar el detalle emergente. Esto pasa en el delegado de transición en el interior de "DetailViewController.swift".
    }
}
