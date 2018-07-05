//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Piercing on 28/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // Para comprobar por consola que el objeto se
    // cancela correcta/ cuando la pantalla se cierra.
    deinit {
        print("deinit \(self)")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Como vamos a hacer nuestras propias restricciones y no las automáticas
        // que nos pone el Interface Builder (IB) eliminamos las constrainsts
        // actuales en la view, en pageControl y en el scrollView. La segunda
        // instrucción nos permite colocar y modificar el tamaño de las vistas
        // manualmente al poner dicha propiedad a true, con esto no entramos en
        // conflicto con Auto Layout ya que para este controlador están activadas.
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
    }
    
    
    // El método "viewWillLayoutSubviews()"  es llamado por UIKit
    // como parte de la fase de diseño de su controlador de vista
    // cuando aparece por primera vez en la pantalla. Es el lugar
    // ideal para cambiar el marco de sus puntos de vista a mano.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Nota: Recuerde que los "bounds"" describen el rectángulo que conforma el interior de una vista,
        // mientras que los "frames" el rectángulo que conforma el interior de una vista, mientras que
        // el describir el rectángulo que conforma el interior de una vista. El "frame" del "scrollView"
        // es el rectángulo visto desde la perspectiva de la vista principal, mientras que el "bounds"
        // del "scrollVieww"es el mismo rectángulo del propio "scrollView".
        // Debido a que el "scrollView" y el "page control" son los dos hijos de la vista principal,
        // sus "frames" se sientan en la misma "coordinate space" como los "boounds" de la vista principal.
        
        
        // La vista de desplazamienteo siempre debe ser tan grande como toda la pantalla,
        // por lo que haremos su "frame" igual a los límites de la vista principal.
        scrollView.frame = view.bounds
        
        pageControl.frame = CGRect(x: 0, y: view.frame.size.height - pageControl.frame.size.height, width: view.frame.size.width, height: pageControl.frame.size.height)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
