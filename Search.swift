//
//  Search.swift
//  StoreSearch
//
//  Created by Usuario on 9/7/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import Foundation


class Search {
    
    // Public properties
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    
    // Private properties
    private var dataTask: URLSessionDataTask? = nil
    
    // Typealias
    typealias SearchComplete = (Bool) -> Void
    
    
    // Con este método pasamos toda la búsqueda que antes se encontraba en el controller "SearchViewController"
    // y que no  debería ser misión del controlador, su misión es la de  pasarle por último los datos a la "UI".
    // La anotación "@escaping" es necesario para "closures" que no se ejecutan de inmediato. Le dice a "Swift"
    // que este "closure" puede necesitar capturar variables tales como "self" y mantenerlas por un tiempo hasta
    // que finalice el "closure" y éste pueda ser finalizado (una vez que la búsqueda se ha realizado).
    //
    func performSearch(for text: String, category: Int, completion: @escaping SearchComplete) { // PASAMOS EL typealias "SearchComplete"
        
        if !text.isEmpty {
            
            // Cada vez que el usuario pulsa el botón 'search' hacemos primero que la tarea sea cancela por si hubiera alguna búsqueda aún activa.
            // Gracias al encadenamiento opcional, si alguna búsqueda aún no ha  terminado, 'dataTask' será todavía 'nil'; esto simplemente ignora
            // la llamada a 'cancel()'. Podíamos haberlo hecho también con if-let. Si ponemos '!' y el opcional es 'nil' se bloqueará la aplicación,
            // dado que cuando la primera vez que el usuario escribe algo en la searchBar, 'dataTask' aún será 'nil' por lo que se caería la app.
            dataTask?.cancel()
            
            // Activamos el activity indicator y refrescamos la tabla.
            isLoading = true
            
            // Aquí ya se realiza búsqueda, por tanto a true.
            hasSearched = true
            searchResults = []
            
            // --- *** IMPLEMENTAMOS URLSESSION *** --- //
            
            // 1.- Creamos el objeto URL añadiéndole el texto de búsqueda y la categoría.
            let url = iTunesURL(searchText: text, category: category)
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
                
                var success = false
                
                // 4.- En el interior del closure tenemos tres parámetros, todos opcionales para
                // que puedan estar a nil, y tienen que desempaquetarse antes de ser utilizados.
                // Error, contine el error, no conecta con el server, no hay red, o fallo de hard.
                // Si error es nil, la comunicación con el server fue exitosa. Response, contine
                // códio y cabeceras de la respuesta del server. Y data, contine los datos reales
                // que nos envía el server, en este caso en formato JSON.
                if let error = error as NSError?, error.code == -999 {
                    print("Failure! \(error)")
                    return // Cancelamos la búsqueda con 'return', el resto del closure se omite.
                }
                
                // Desenvolvemos el objeto data opcional, lo parseamos, y lo
                // pasamos  para parsearlo convirtiéndolo  en un diccionario.
                if let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let jsonData = data,
                    let jsonDictionary = self.parse(json: jsonData) {
                    
                    // Aquí lo convertimos el contenido del diccionario en un objeto serchResults.
                    self.searchResults = self.parse(dictionary: jsonDictionary)
                    // Por último lo ordenamos.
                    self.searchResults.sort(by: <)
                    
                    print("Successss!!")
                    // Paramos el spinner.
                    self.isLoading = false
                    // Encotrados resultados
                    success = true
                    
                }  // --- *** FIN URLSESSION --- *** //
                
                
                // Si no hay resultados reseteamos search y paramos spinner.
                if !success {
                    self.hasSearched = false
                    self.isLoading = false
                }
                
                // Closure-completion le pasamos si hubo no hubo resultados en la búsqueda: success --> true or false.
                // Se ejecuta cuando la búsqueda haya concluido.
                
                // Para ejecutar el código del closure, simplemente llámalo como llamarías a cualquier función o
                // método: closureName (parámetros). Usted llama completion (true) al éxito y  completion (false)
                // al fallar. Esto se hace para que SearchViewController pueda  volver a cargar su vista de tabla
                // o, en el caso de un error, muestre una vista de alerta.
                DispatchQueue.main.async {
                    completion(success)
                }
            })
            
            // 5.- Una vez creada la tarea de datos, llamar al método 'resume()' para inicializar el proceso,
            // enviando una solicitud al server. Todo sucede en un subproceso en segundo plano, por lo que la
            // aplicación es liberada inmediatamente para continuar (URLSession es asíncrona).
            dataTask?.resume()
        }
    }
    
    
    // MARK: NetWork
    
    // Función que devuelve un objeto URL válido.
    private func iTunesURL(searchText: String, category: Int) -> URL {
        
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
    
    // MARK: ParseJSON
    
    // Función que convierte los Strings de búsqueda en un diccionario de objetos JSON y los devuelve.
    private func parse(json data: Data) -> [String : Any]? {
        
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
    private func parse(dictionary: [String : Any]) -> [SearchResult] {
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
    
    private func parse(track dictionary: [String : Any]) -> SearchResult {
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
    
    private func parse(audiobook dictionary: [String: Any]) -> SearchResult {
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
    
    private func parse(software dictionary: [String: Any]) -> SearchResult {
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
    
    private func parse(ebook dictionary: [String: Any]) -> SearchResult {
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
}
