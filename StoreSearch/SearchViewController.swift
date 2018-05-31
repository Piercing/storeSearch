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
    
    // Variables globales.
    var searchResults: [SearchResult] = []
    var hasSearched = false
    
    // MARK: Structs
    
    // Struct para las identificaciones de los nombres de las celdas a registrar.
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
    }
    
    // MARK: Lifecycle
    
    // La vista ya se ha cargado y está en memoria.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuramos las dimensiones de la tabla, dejamos 64 puntos de espacio en la
        // parte superior, para que pueda albergar correctamente la searchBar y la status Bar.
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        // Registramos las celdas que se van a utilizar/reutilizar.
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        // Configuramos la altura de las celdas de la tabla.
        tableView.rowHeight = 80
        
        // Hacemos que el teclado aparezca al cargarse la view y al hacer clic en la searchBar.
        searchBar.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: NetWork

// Función que devuelve un objeto URL válido.
func iTunesURL(searchText: String) -> URL {
    
    // Escapamos los espacios en blanco entre los Strings de entrada en
    //  la searchBar, codifica en UTF-8 que casi siempre va a funcionar.😎
    let escapeSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    
    // Recibimos en el parámetro el texto a buscar que se adjunta al final de la url dada.
    let urlString = String(format: "https://itunes.apple.com/search?term=%@", escapeSearchText)
    let url = URL(string: urlString)
    // Como URL(String) es uno de los inicializadores 'failable',
    // devuleve un opcional, de ahí que lo desempaquetemos.
    return url!
}

// Función que devuelve un nuevo objeto String con los datos que recibe del servidor.
// Le decimos a la aplicación que interprete los datos como texto UTF-8. Es importante
// que los datos que enviemos y recibamos del servidor estén de acuerdo en la codificación.
func performStoreRequest(url: URL) -> String? {
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        print("Download Error: \(error)")
        return nil
    }
}

//func showNetWorkError() {
//    let alert = UIAlertController(title: "Whoosp", message: "There was an error reading from the iTunes Store. Please try again", preferredStyle: .alert)
//    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
//    alert.addAction(action)
//    present(alert, animated: true, completion: nil)
//}

// MARK: ParseJSON

// Función que convierte los Strings de búsqueda en un diccionario de objetos JSON y los devuelve.
func parse(json: String) -> [String : Any]? {
    
    // Utilizamos un guard por si los datos no se pueden codificar en UTF-8.
    guard let data = json.data(using: .utf8, allowLossyConversion: false)
        else { return nil }
    do {
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
            // por lo que utilizamos 'if --> let' para deselvolver esos valores. Y por que el
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
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Si la searchBar contiene datos para la búsquda...
        if !searchBar.text!.isEmpty {
            // Hacemos que el teclado se oculte al pulsar el botón "Buscar" del dispositivo.
            searchBar.resignFirstResponder()
            
            // Aquí ya existe una primera búsqueda. Flag a true para que nos permita
            // mostrar las filas correspondientes dentro del método "numberOfRowsInSection".
            hasSearched = true
            // Array para almacenar los datos devueltos por la búsqueda.
            searchResults = []
            
            // Pasamos el texto introducido en la searchBar para formar la URL final de búsqueda en iTunes.
            let url = iTunesURL(searchText: searchBar.text!)
            print("URL: '\(url)'")
            // Invocamos a performStoreRequest() con el objeto URL como parámetro y devuelve
            // los datos JSON que recibe desde el servidor. Si todo va bien, este método
            // devuelve un objeto String que contiene los datos JSON que estamos buscando.
            if let jsonString = performStoreRequest(url: url) {
                // Parseamos los datos obtenidos a un diccionario --> par: key-value.
                if let jsonDictionary = StoreSearch.parse(json: jsonString) {
                    print("Dictionary \(jsonDictionary)")
                    // Llamamos la siguiente método para parsear los datos recibidos y se los asignamos a la variable
                    // de instancia de la tableView para que  pueda mostrar los objetos obtenidos en la búsqueda real.
                    searchResults = StoreSearch.parse(dictionary: jsonDictionary)
                    // Ordenamos el array por nombre ascendente. Esta línea dice: "Clasificar el array en orden descendente".
                    searchResults.sort (by: <)
                    // Recargamos la tabla. Update.
                    tableView.reloadData()
                    return
                }
            }
            // Mostrarmos con un alert el error producido si cualquiera de los if-->let ha fallado.
            showNetWorkError("Whoops", "here was an error reading from the iTunes Store. Please try again")
        }
    }
    
    // Función para ajustar la posición de la searchBar y que quede por
    // encima de la tabla y se vea correctamente extendiéndose correctamente.
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    // MARK: Others
    
    func kindForDisplay(_ kind: String) -> String {
        switch kind {
        case "album": return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
}

// MARK: DataSource

//-- Extensión para DataSource de la tabla.
extension SearchViewController: UITableViewDataSource {
    
    //-- Funciones requeridas por el DataSource.
    
    // Número de filas que tendrá la tabla.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Si no hubo aún una búsqueda no devuelve ninguna fila.
        if !hasSearched {
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
        
        // Si no hay resultados...
        if searchResults.count == 0 {
            // Devuleve la celda con el identificador de la celda "nada encontrado".
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            
            // Por contrario, si hay resultados...
        } else {
            
            // Creamos la celda ha reutilizar, con el identificador de esta y de tipo "SearchResultCell".
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            // Almacenamos el resultado para el "indexpath" de la fila correspondiente, y
            // asignamos los valores que tendrán las views de la celda, y devolvemos la celda.
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            if searchResult.artistName.isEmpty { cell.artistNameLabel.text = "Unknown" }
            else { cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, kindForDisplay( searchResult.kind))}
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
    
    // Se llama a este método antes de que el usuario cambie la selección,
    // devolviendo un nuevo indexpath, o nil, para cambiar la selección propuesta.
    func tableView(_ tableView: UITableView,  willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        // Si no hay resultados, devuelve nil, de lo contrario, devuelve el nuevo indexpath seleccionado.
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}

