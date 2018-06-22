//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by Piercing on 21/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    
    var searchResult: SearchResult!
    
    // Este init se invoca  para cargar el controlador de la vista del storyboard.
    // Aquí UIKit  dice que este  controlador de vista utilizará  una presentación
    // personalizada y se establece el delegado que llamará al método que se acaba
    // de implementar.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cambiamos el color de la view, que afectará a los dos botones, precio y cerrar.
        view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        // Redondeamos las esquinas de la view
        popupView.layer.cornerRadius = 10
        
        
        // Creamos un 'gesture recognizer' que escucha los toques en cualquier lugar
        // en este controlador de vista y que llama al método 'close()' en respuesta.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
        
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        if let _ = searchResult  {
            updateUI()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI
    
    func updateUI() {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else { artistNameLabel.text = searchResult.artistName }
        
        kindLabel.text = searchResult.kindForDisplay()
        genreLabel.text = searchResult.genre
    }
    
    // MARK: - Actions
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
}


// Los métodos de este protocolo delegado de UIKit dicen qué objetos se deben utilizar para realizar la transición al controlador de la vista Detalle.
// Utilizaremos ahora nuestro nuevo controlador, la clase DimmingPresentationController en lugar del controlador de presentación estándar.
extension DetailViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
}


// Con esta extesión delegado podemos cerrar la ventana de detalle con solo tocar fuera de ella en la pantalla.
// Cualquier otro toque-tap debe ser ignorado. Devuelve true cuando se toca en la pantalla fuera de la ventana
// pop-up y falso si tocamos o hacemos tap dentro de la ventana modal del pop-up.
extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_gestureReconignizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}






















