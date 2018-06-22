//
//  SearchResultCell.swift
//  StoreSearch
//
//  Created by Piercing on 21/5/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit


// Cuando el método "dequeueReusableCell(…)" de la tabla es llamado con este
// .xib, la vista de la tabla devolverá un objeto de tipo "SearchResultCell".
class SearchResultCell: UITableViewCell {
    
    var downloadTask: URLSessionDownloadTask?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    // MARK: Lifecycle
    
    // Método similar a viewDidLoad de los view controllers.
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: Cells
    
    // Este método cancela cualquier descarga
    // de imagen que aún está en progreso.
    override func prepareForReuse() {
        super.prepareForReuse()
        
        downloadTask?.cancel()
        downloadTask = nil
        
        print("PREPARE FOR REUSE")
    }
    
    
    // MARK: Configure
    
    func configure(for searchResult: SearchResult)  {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = String(format:" %@ (%@)", searchResult.artistName, searchResult.kindForDisplay())
        }
        
        // Esto le dice a UIImageView que cargue la imagen de 'artworkSmallURL' y la coloque en la image view de la
        // celda. Mientras la imagen real 'artwork' se descarga la image view muestra una imagen tipo 'placeholder'.
        // El objeto URLSessionDownloadTask devuelto por loadImage(url) se coloca en una nueva variable de instancia
        // 'downloadTask'.
        artworkImageView.image = UIImage(named: "Placeholder")
        if let smallURL = URL(string: searchResult.artworkSmallURL) {
            downloadTask = artworkImageView.loadImage(url: smallURL)
        }
    }
}
