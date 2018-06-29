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
    
    var landscapeViewController: LandscapeViewController?
    
    var searchResults: [SearchResult] = []
    // Es opcional, ya que no tendremos un dataTask,
    // hasta que el usuario haga una búsqueda --> ?.
    var dataTask: URLSessionDataTask?
    var hasSearched = false
    var isLoading = false
    
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
    
    
    // MARK: NetWork
    
    // Función que devuelve un objeto URL válido.
    func iTunesURL(searchText: String, category: Int) -> URL {
        
        let entityName: String
        
        switch category {
        case 1:  entityName = "musicTrack"
        case 2:  entityName = "software"
        case 3:  entityName = "ebook"
        default: entityName = ""
            
        }
        
        // Escapamos los espacios en  blanco entre los Strings de entrada en
        // la searchBar, codifica en 'UTF-8' que casi siempre va a funcionar.
        let escapeSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        // Recibimos en el parámetro el texto a buscar que se adjunta al final
        //  de la url dada y el índice de la categoría (books, software, etc).
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapeSearchText, entityName)
        let url = URL(string: urlString)
        // Como URL(String) es uno de los inicializadores 'failable',
        // devuleve un opcional '?',  de ahí que lo desempaquetemos.
        return url!
    }
    
    // MARK: Actions
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    
    // MARK: ParseJSON
    
    // Función que convierte los Strings de búsqueda en un diccionario de objetos JSON y los devuelve.
    func parse(json data: Data) -> [String : Any]? {
        
        do {
            // En el objeto data ya tenemos el texto JSON.
            // Los serializamos, covirtiéndolos en Objetos Foundation.
            // En este caso en un diccionario, de par clave-valor String:Any.
            return  try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        } catch  {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    // Función que hace distinción entre los campos el 'kind' y el 'wrapperType', al igual que lo hace iTunes.
    // Este método pasa por el diccionario de nivel superior y mira cada resultado de la búsqueda.
    func parse(dictionary: [String : Any]) -> [SearchResult] {
        // 1.- Programación defensiva, para asegurarnos que el diccionario tiene
        // una clave denominada  "results" que contiene un  array en su interior.
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected 'results' array'")
            // Si algo va mal, devolvemos un array vacío.
            return []
        }
        var searchResutls: [SearchResult] = []
        // 2.- Una vez que se ha cumplido que existe dicho array,
        // iteramos para obtener cada uno de los elementos del array.
        for resultDict in array {
            // 3.- Cada uno de los elementos de array es otro diccionario,
            // pero como 'resultDict' no es un diccionario como nos gustaría que fuese,
            // utilizamos 'Any' ya que los elementos del array pueden ser de cualquier tipo.
            if let resultDict = resultDict as? [String : Any] {
                // 4.-Para cada uno de los diccionarios, imprimimos el valor de su 'wrapperType'
                // y el campo 'kind'. La indexación de un diccionario siempre nos da un opcional
                // por lo que utilizamos 'if --> let' para desenvolver esos valores. Y porque el
                // diccionario solo contiene valores de tipo Any también lo casteamos a tipo String.
                var searchResult: SearchResult?
                if let wrapperType = resultDict["wrapperType"] as? String {
                    switch wrapperType {
                    case "track": searchResult = parse(track: resultDict)
                    case "audiobook": searchResult = parse(audiobook: resultDict)
                    case "software": searchResult = parse(software: resultDict)
                    default: break
                    }
                } else if let kind = resultDict["kind"] as? String, kind == "ebook" { searchResult = parse(ebook: resultDict) }
                if let result = searchResult { searchResutls.append(result) }
            }
        }
        // Devolvemos un array con objetos searchResult.
        return searchResutls
    }
    
    func parse(track dictionary: [String : Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        // Casteamos cada propiedad a su tipo, String y Double en este caso ya que el diccionario es de tipos [String : Any]
        // por lo que la key siempre será de tipo String, pero el valor puede variar, de ahí el casteo forzado a cada tipo.
        searchResult.kind = dictionary["kind"] as! String
        searchResult.name = dictionary["trackName"] as! String
        searchResult.currency = dictionary["currency"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        // Nos aseguramos con if--> let en estos dos parámetros porque
        // a veces estos datos no vienen en los datos del JSON. Podríamos
        // asegurar los anteriores, siendo muy precavidos poniéndole el ?
        // por ejemplo: searchResult.kind = dictionary["kind"] as! String?
        if let price = dictionary["trakePrice"] as? Double { searchResult.price = price }
        if let genre = dictionary["primaryGenreName"] as? String { searchResult.genre = genre }
        
        return searchResult
    }
    
    func parse(audiobook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        // No tiene 'kind' los audioBooks, lo hardcodeamos directamente.
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["collectionPrice"] as? Double { searchResult.price = price }
        if let genre = dictionary["primaryGenreName"] as? String {searchResult.genre = genre }
        
        return searchResult
    }
    
    func parse(software dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double { searchResult.price = price }
        if let genre = dictionary["primaryGenreName"] as? String { searchResult.genre = genre }
        return searchResult
    }
    
    func parse(ebook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double { searchResult.price = price }
        
        // Los  audioBooks no tienen un campo  "primaryGenreName", pero sí una gran  variedad de genres.
        // Utilizamos el método 'joined(separator)' para unir estos nombres de género en un solo String.
        if let genres: Any = dictionary["genres"] { searchResult.genre = (genres as! [String]).joined(separator: ", ") }
        return searchResult
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
            let searchResult = searchResults[indexPath.row]
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
        
        if !searchBar.text!.isEmpty {
            
            searchBar.resignFirstResponder()
            
            // Cada vez que el usuario pulsa el botón 'search' hacemos primero que la tarea sea cancela por si hubiera alguna búsqueda aún activa.
            // Gracias al encadenamiento opcional, si alguna búsqueda aún no ha  terminado, 'dataTask' será todavía 'nil'; esto simplemente ignora
            // la llamada a 'cancel()'. Podíamos haberlo hecho también con if-let. Si ponemos '!' y el opcional es 'nil' se bloqueará la aplicación,
            // dado que cuando la primera vez que el usuario escribe algo en la searchBar, 'dataTask' aún será 'nil' por lo que se caería la app.
            dataTask?.cancel()
            
            // Activamos el activity indicator y refrescamos la tabla.
            isLoading = true
            tableView.reloadData()
            
            // Aquí ya se realiza búsqueda, por tanto a true.
            hasSearched = true
            searchResults = []
            
            // --- *** IMPLEMENTAMOS URLSESSION *** --- //
            
            // 1.- Creamos el objeto URL añadiéndole el texto de búsqueda y el índice seleccionado del segment Control.
            let url = self.iTunesURL(searchText: searchBar.text!, category: segmentControl.selectedSegmentIndex)
            // 2.- Obtenemos el objeto URLSession, mediante la sesión compartida,
            // utilizando una configuración predeterminada con respecto al alma-
            // cenamiento en caché, cookies, y otras cosas web. Podemos crear
            // nuestra propia configuración, creando nuestros propios objetos
            // URLSessionConfiguration y URLSession.
            let session = URLSession.shared
            // 3.- Crear la tarea  de datos, 'dataTask', para  enviar  solicitudes
            // HTTPS GET al servidor, pasándole la url, y un closure, el cual será
            // invocado  cuando la  tarea haya recibido la  respuesta del servidor.
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                // 4.- En el interior del closure tenemos tres parámetros, todos opcionales para
                // que puedan estar a nil, y tienen que desempaquetarse antes de ser utilizados.
                // Error, contine el error, no conecta con el server, no hay red, o fallo de hard.
                // Si error es nil, la comunicación con el server fue exitosa. Response, contine
                // códio y cabeceras de la respuesta del server. Y data, contine los datos reales
                // que nos envía el server, en este caso en formato JSON.
                if let error = error as NSError?, error.code == -999 {
                    print("Failure! \(error)")
                    return // Cancelamos la búsqueda con 'return', el resto del closure se omite.
                    
                    
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    
                    // Desenvolvemos el objeto data opcional, lo parseamos, y lo
                    // pasamos  para parsearlo convirtiéndolo  en un diccionario.
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        // Aquí lo convertimos el contenido del diccionario en un objeto serchResults.
                        self.searchResults = self.parse(dictionary: jsonDictionary)
                        // Por último lo ordenamos.
                        self.searchResults.sort(by: <)
                        
                        // Actualizamos la tabla con los datos nuevos,
                        // paramos el spinner. Todo en el hilo principal.
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        // Salimos.
                        return
                        
                    } // --- *** FIN URLSESSION --- *** //
                    
                    // Ponemos este código aquí por si algo ha ido mal, avisando al usuario de que algo ha ido mal.
                    // Actualizamos la tabla antes, ya que la vista de la tabla necesita ser renovada para deshacerse
                    // del 'Loading...' y todo en el hilo principal.
                    DispatchQueue.main.async {
                        self.hasSearched = false
                        self.isLoading = false
                        self.tableView.reloadData()
                        self.showNetWorkError("Whoops", "There was an error reading from the iTunes Store. Please try again.")
                    }
                    
                } else {
                    print("Success! \(response!)")
                }
            })
            
            // 5.- Una vez creada la tarea de datos, llamar al método 'resume()' para inicializar el proceso,
            // enviando una solicitud al server. Todo sucede en un subproceso en segundo plano, por lo que la
            // aplicación es liberada inmediatamente para continuar (URLSession es asíncrona).
            dataTask?.resume()
        }
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
        
        if isLoading {
            
            // Devolvemos uno porque necesitamos una fila para mostrar la celda de 'Cargando...'
            return 1
            
            // Si no hubo aún una búsqueda no devuelve ninguna fila.
        } else if !hasSearched {
            return 0
            
            // Si no hay resultados, devuelve una fila.
        } else if searchResults.count == 0 {
            return 1
            
            // Si hay resultados, devuleve tantas filas como contenga el array que almacena los datos.
        } else {
            return searchResults.count
        }
    }
    
    // Configura la celda a mostrar para el indexpath dado.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        }
        
        // Si no hay resultados...
        if searchResults.count == 0 {
            // Devuleve la celda con el identificador de la celda "nada encontrado".
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            
        } else { // Por contrario, si hay resultados...
            
            // Creamos la celda ha reutilizar, con el identificador de ésta y de tipo "SearchResultCell".
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            // Almacenamos el resultado para el "indexpath" de la fila/row correspondiente, y
            // asignamos los valores que tendrán las views de la celda, y devolvemos la celda.
            let searchResult = searchResults[indexPath.row]
            
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
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}






























