
//
//  AppDelegate.swift
//  StoreSearch
//
//  Created by Piercing on 21/5/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//


// Modelo para los datos de la aplicación.
class SearchResult {
    var name = ""
    var artistName = ""
    var artworkSmallURL = ""
    var artworkLargeURL = ""
    var storeURL = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
    
    // MARK: Others
    
    func kindForDisplay() -> String {
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

// Creamos una función llamada '<' que contiene el mismo código que hacemos
// en el método 'sort' en 'SearchViewController' en su closure de cierre.
// Esta vez los dos 'SearchResult' de búsqueda se denominan 'lhs' y 'rhs'
// para el lado izquierdo y derecho, respectivamente. Lo utilizamos en 'SearchViewController'.
func < (lhs:SearchResult, rhs: SearchResult) -> Bool {
    return lhs.artistName.localizedStandardCompare(rhs.artistName) == .orderedAscending
}
