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
    func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath) {
        
        // Omitir el resaltado de la celda al ser deseleccionada.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Se llama a este método antes de que el usuario cambie la selección de fila,
    // devolviendo un nuevo indexpath, o nil, para cambiar la selección propuesta.
    func tableView(_ tableView: UITableView,  willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        // Si no hay resultados, devuelve nil, de lo contrario, devuelve el nuevo indexpath seleccionado.
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

