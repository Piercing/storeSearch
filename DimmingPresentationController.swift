//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Piercing on 21/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    // Creamos aquí el objeto de la calse GradientView, ya que esta clase es la encargada de mostrar la presentación del efecto
    // secundario, liberando así a la clase DetailView de cualquier  responsabilidad. El gradiente es realmente un efecto secundario
    // de hacer una presentación, por lo que peretenece al controlador de presentación.
    
    // Los métodos "presentationTransitionWillBegin" se invocan cuando el nuevo controlador de vista está a punto de ser mostrado en
    // pantalla. Aquí se crea el objeto GradientView, que hace que sea tan grande como el "containerView" y lo inserta detrás de todo
    // lo demás en esta vista "container view". Ésta vista recipiente es un nuevo punto de vista que se coloca en la parte superior de
    // la "SearchViewController" y contiene los puntos de vista de la  DetailViewController. Así que esta pieza de código coloca la
    // GradientView entre esas dos pantallas.
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
        
        // Se establece el valor de alfa de la vista de gradiente a 0 para que sea completamente transparente y luego animar de
        // nuevo a 1 (o 100%) y totalmente visible, lo que resulta en un simple fundido de entrada. Eso es un poco más sutil que
        // hacer el gradiente aparecer de manera tan abrupta. Lo especial aquí es transitionCoordinator. Esta es la policía de
        // tráfico UIKit a cargo de coordinar el controlador de presentación y controladores de animación y todo lo que sucede
        // cuando se presenta un nuevo controlador de vista. La cosa importante a saber sobre el transitionCoordinator es que
        // ninguna de sus animaciones se debe hacer en un cierre pasó a animateAlongsideTransition para mantener la transición
        // sin problemas. Si los usuarios querían animaciones agitadas, habrían comprado los teléfonos Android!
        dimmingView.alpha = 0
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            }, completion: nil) }
    }
    
    // "dismissalTransitionWillBegin()", se utiliza para animar la vista gradiente de fuera de la vista cuando se desestimó el detalle emergente.
    // Esto hace el inverso: el anime el valor alfa de nuevo a 0% para hacer la vista gradiente de fundido de salida.
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator { coordinator.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
        }
    }
}
