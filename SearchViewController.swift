//
//  ViewController.swift
//  StoreSearch
//
//  Created by Piercing on 21/5/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

/*
 Clase SearchViewController para la search Bar y la table view.
 */
class SearchViewController: UIViewController {
    
    // IBOutlets para la searchBar y la tableView.
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    // Variables globales/instancia.
    
    let search = Search()
    var landscapeViewController: LandscapeViewController?
    
    // MARK: Structs
    
    // Struct para las identificaciones de los nombres de las celdas a registrar.
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell      = "LoadingCell"
    }
    
    // MARK: Lifecycle
    
    // La vista ya se ha cargado y está en memoria.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuramos las  dimensiones de la tabla, dejamos 108 puntos de espacio
        // en la parte superior, para que pueda albergar correctamente la searchBar
        // y la status Bar y la barra de navegación para el UISegment.
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        
        // Registramos las celdas que se van a utilizar/reutilizar.
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        // Configuramos la altura de las celdas de la tabla.
        tableView.rowHeight = 80
        
        // Hacemos que el teclado aparezca al cargarse la view y al hacer clic en la searchBar.
        searchBar.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    
    
    
    // MARK: UISearchBar
    
    // Función propia de UISearchBar, se llamma al pulsar el botón 'search/buscar'
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    // MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = search.searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    // MARK: - Orientations
    
    // Cada vez que un "trait colletion" cambia, (rotar dispositivo, la fuente de letras, el idioma, etc)
    // UIKit llama a este método para dar al controlador la oportunidad de adaptarse a los nuevos traits.
    // Lo que nos importa aquí son las "size classes", que nos permite diseñar unas interfaces de usuario
    // que son independiente de las dimensiones o la orientación real del dispositivo, --> "iPhone o iPad".
    // Comprobamos aquí si rota el dispositivo, viendo cómo cambia la size clase de tamaño, como observamos.
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact: showLandscape(with: coordinator) // el dispositivo se voltea/rota a Landscape
        case .regular, .unspecified: hideLandscape(with: coordinator) // el dispositovo está de vuelta, ocultar la vista Landscape.
        }
    }
    
    // **** NOTA ****:  A pesar de que aparecerá en la parte superior de todo lo demás, la pantalla del landscape no se presenta de
    // forma modal. Ésta está “contenida” en su controlador de vista padre, y por lo tanto pertenece y es administrada por ella, no
    // es independiente como una pantalla modal. Esta es una distinción importante.
    
    // View controlador también se utiliza para los controladores barra de navegación y de la ficha donde el UINavigationController
    // y UITabBarController “Envolver” a sus controladores de vista del niño.
    
    // Por lo general, cuando se quiere mostrar un controlador de vista que se hace cargo de toda la pantalla tendrá que utilizar
    // un segue modal. Pero cuando se quiere sólo una parte de la pantalla que será gestionado por su propio controlador de
    // vista que lo convierte en un controlador de vista hijo.
    
    // Es una de las razones por las que no está utilizando un segue modal para la pantalla del landscape en esta aplicación, a pesar
    // de que se trata de un controlador de vista de pantalla completa, es decir que el detalle emergente ya está presentado de
    // forma modal y esto podría causar conflictos. Además, quería mostrarle una alternativa divertida a segues modal.
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        
        // 1.- Nunca debe ocurrir que la app cree una instancia de una segunda vista landscape cuando
        // ya se está obteniendo una. Si "guard" es nil codifica este requisito, mostrar landscape.
        // Si no se cumple, entonces simplemente retorna inmediateamente.
        guard landscapeViewController == nil else { return }
        
        // 2.- Encontrar la escena con el ID "LandscapeViewController" en el storyboard e instanciarlo,
        // debido a que no tenemos un segue, debemos hacerlo manualmente, por eso pusimos el ID en el
        // campo ID del guión del storyboard.
        landscapeViewController = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        // La variable de instancia "landscapeViewController" es un opcional,
        // de ahí que necesitemos desempaquetarlo antes de poder continuar.
        if let controller = landscapeViewController {
            
            // Pasamos los  resultados  al array de  LandScape; tenemos que estar seguros  de llenar el array,
            // con los resultados de la búsqueda, antes de acceder a la propiedad del LandScapeViewController,
            // dado  que se  disparará la vista para  ser cargada y  ejecutada por  el método "viewDidLoad()".
            
            // El view Controller va a leer del array los resultados en viewDidLoad() para construir el contenido
            // de su scroll view. Pero si accedemos al controller.view antes de establecer los "searchResults",
            // esta propiedad estará todavía  a nil y no podremos hacer nada para rellenar los botones en land.
            controller.search = search
            
            // 3.- Ajustar el tamaño y la posición del nuevo view controller. Esto hace la vista
            // tan grande como "SearchViewController" que cubre toda la pantalla. El "frame" es el
            // rectángulo que describe la posición y el tamaño de la vista en términos de su supervista.
            // Para mover un objeto de su posición y su tamaño final normalmente se establece sus límites
            // con "frame".
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            
            // 4.- A continuación los passo mínimos necesarios para agregar el contenido de un view controller
            // a otro view controller, en este orden:
            // a.- Añadir el view controller landscape como subvista. Esto lo coloca en la parte superior de la
            // table view, search bar y segmente control.
            // b.- En segundo lugar, le decimos a la SearchViewController que LandscapeViewController hace la
            // gestión de esa parte de la pantalla, usando addChildViewController(). Si nos olvidamos de este
            // paso, entonces el nuevo viewController no siempre funcionará correctamente.
            // c.- Decirle al nuevo viewController que ahora tiene un viewController padre con "didMove(toParentController)"
            
            // En este nuevo esquema, SearchViewController es el viewController padre y LandscapeViewController es el hijo.
            // En otras palabras, la pantalla Landscape está incustrada dentro de SearchViewController.
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            // ******* NOTA *******: Todavía se están haciendo las mismas cosas que antes, excepto que ahora landscape comienza
            // completamente transparente (alfa = 0) y se desvanece lentamente mientras que la rotación tiene lugar hasta que la
            // completamente visible ( alfa = 1). Ahora ves por qué el UIViewControllerTransitionCoordinator Se necesita objeto,
            // por lo que la animación se puede realizar junto con el resto de la transición de los viejos rasgos a lo nuevo.
            // Esto asegura que las animaciones se ejecutan todo lo suavemente posible. La llamada a animar (alongsideTransition, completion)
            // toma dos closures: el primero es para la animación en sí, el segundo es un “completion handler” que es llamado una
            // vez finalizada la animación. El “completion handler” le da la oportunidad de retrasar la llamada a "didMove
            // (toParentViewController)" hasta que la animación ha terminado. Ambos cierres se les da un parámetro “transition coordinator context”
            // (el mismo contexto que los controladores de animación consiguen), pero no es muy interesante aquí y se utiliza el comodín _ paraignorarlo.
            
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 1
                // Ocultamos el teclado al girar
                self.searchBar.resignFirstResponder()
            },  completion: { _ in
                controller.didMove(toParentViewController: self)
                if self.presentationController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    // Un objeto conforme a este protocolo es devuelto por: ----> [UIViewController
    // transitionCoordinator] cuando una transición activa o presentación / despido
    // es en vuelo. Un controlador de contenedor no puede vender tal objeto. Esto es
    // un objeto efímero que se libera después de que finaliza la transición y el la
    // última devolución de llamada se ha realizado.
    
    // Para que la aplicación compile, añadir el método “hideLandscape” vacio.
    // A continuación le damos la implementación para que al volver a posición
    // vertical desaparezca el modo landscape.
    
    func hideLandscape(with coordinator:UIViewControllerTransitionCoordinator) {
        
        if let controller = landscapeViewController {
            // Le decimos al viewController landscape que ya no
            // tiene padre y que abandona la vista de jerarquía.
            controller.willMove(toParentViewController: nil)
            
            coordinator.animate(alongsideTransition: { _ in
                
                // Hacemos que al girar, si está la ventana modal, el pop-up de la fila pulsada desaparezca en el modo landscape.
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
                controller.view.alpha = 0
            }, completion: { _ in
                // Quitamos la vista de la pantalla.
                controller.view.removeFromSuperview()
                // Quitamos del padre que es el que realmente tiene dispone de los viewControllers.
                controller.removeFromParentViewController()
                // Establecemos la variable de instacia a "nil" con el fin de eliminar la última
                // referencia fuerte a LandscapeViewController, dado que ya ha terminado con él.
                self.landscapeViewController = nil
            })
        }
    }
}

// MARK: Extensions

//-- Extendemos el controlador para crear una función que mostrará el error producido en caso de que algo falle.
extension SearchViewController {
    public func showNetWorkError(_ title:String, _ message:String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertVC.addAction(okAction)
        present(alertVC, animated: true, completion: nil)
    }
}

//-- Esta extensión va a ser el delegado de la searchBar. Se llama al interactuar con la searchBar.
extension SearchViewController: UISearchBarDelegate {
    
    // Función que se llama al pulsar el botón "Buscar/Search" del dispositivo.
    func performSearch() {
        
        // Hacemos que la nueva clase creada "Search" haga el trabajo de búsqueda que se hacía antes aquí.
        search.performSearch(for: searchBar.text!, category: segmentControl.selectedSegmentIndex, completion: { success in
            if !success {
                self.showNetWorkError("Error NetWork", "A connection error occurred when accessing our servers")
            }
            // Recargamos la tabla.
            self.tableView.reloadData()
        })
        
        // Recargamos la tabla y ocultamos el teclado.
        tableView.reloadData()
        searchBar.resignFirstResponder()

    }
    
    // Función para ajustar la posición de la 'searchBar' y que quede por encima de la tabla y
    // se vea correctamente extendiéndose correctamente hasta el borde superior de la pantalla.
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

// MARK: DataSource

//-- Extensión para DataSource de la tabla.
extension SearchViewController: UITableViewDataSource {
    
    //-- Funciones requeridas por el DataSource.
    
    // Número de filas que tendrá la tabla.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if search.isLoading {
            
            // Devolvemos uno porque necesitamos una fila para mostrar la celda de 'Cargando...'
            return 1 // Loanding...
            
            // Si no hubo aún una búsqueda no devuelve ninguna fila.
        } else if !search.hasSearched {
            return 0 // Not searched yet
            
            // Si no hay resultados, devuelve una fila.
        } else if search.searchResults.count == 0 {
            return 1 // Nothing Found
            
            // Si hay resultados, devuleve tantas filas como contenga el array que almacena los datos.
        } else {
            return search.searchResults.count
        }
    }
    
    // Configura la celda a mostrar para el indexpath dado.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if search.isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        }
        
        // Si no hay resultados...
        if search.searchResults.count == 0 {
            // Devuleve la celda con el identificador de la celda "nada encontrado".
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            
        } else { // Por contrario, si hay resultados...
            
            // Creamos la celda ha reutilizar, con el identificador de ésta y de tipo "SearchResultCell".
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            // Almacenamos el resultado para el "indexpath" de la fila/row correspondiente, y
            // asignamos los valores que tendrán las views de la celda, y devolvemos la celda.
            let searchResult = search.searchResults[indexPath.row]
            
            // Llamamos al método configure de la clase SearchResultCell.
            cell.configure(for: searchResult)
            return cell
        }
    }
}

// MARK: Delegate

//-- Extensión para el Delegado de la tabla.
extension SearchViewController: UITableViewDelegate {
    
    //-- Funciones requeridas por el Delegado.
    
    // Función para la celda que se ha seleccionado.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Omitir el resaltado de la celda al ser deseleccionada.
        tableView.deselectRow(at: indexPath, animated: true)
        
        //
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    // Se llama a este método antes de que el usuario cambie la selección de fila,
    // devolviendo un nuevo indexpath, o nil, para cambiar la selección propuesta.
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        // Si no hay resultados, devuelve nil, de lo contrario, devuelve el nuevo indexpath seleccionado.
        if search.searchResults.count == 0 || search.isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}






























