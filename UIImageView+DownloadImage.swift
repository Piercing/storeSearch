//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by Piercing on 5/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        
        let session = URLSession.shared
        // 1.- Después de obtener una referencia shared URLSession, creamos una task de descarga.
        // Esto es similar a una "task de datos", y además  guarda  el archivo descargado en una
        // ubicación temporal en disco en lugar de mantenerlo en memoria.  'weak': enlace débil,
        // si la imagen no existe aún para que no se caiga la app, y 'self' es la propia UIImageView.
        let downloadTask = session.downloadTask(with: url, completionHandler: { [weak self] url, response, error in
            // 2.- Dentro del 'completion hadnler', desempaquetamos la url del archivo descargado
            // (esta URL apunta a un archivo local en vez de a una dirección de Internet),
            // y comprobamos también si ha habido algún error.
            if error == nil, let url = url,
                // 3.- con esta url local, se puede cargar el archivo en un objeto Data
                // y luego hacer una imagen de ésta. Es posible que la construcción de
                // la imgen falle, si lo que hemos descargado no era una imagen válida
                // o un 404 o  algo inesperado. Comprobamos cada paso, prog. defensiva.
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data) {
                // 4.- Una vez que tengamos la imagen se  puede poner ya en la la propiedad imagen de 'UIImageView's'.
                // Debemos de  hacerlo en el hilo principal, ya que  es 'UI'. El tema difícil es que la UIImage ya no
                // exista por el  momento en la imagen  que nos llega del "servidor". Puede tardar unos segundos y el
                // usuario  puede navegar a través de la  aplicación en la medida  de lo posible. Esto no sucederá en
                // esta parte de la aplicación, ya que la imagen es  parte de un celda de la tableView que se recicla
                // pero que no se retira. En este caso no deseamos ajustar la image si UIImageView  no es visible aún.
                // Es por eso que la list de captura para este cierre incluye [weak self], donde self aquí se refiere
                // a la propia UIImageView. Dentro de 'DispatchQueue' es necesario comprobar si 'self' todavía existe;
                // es decir, la UIImageView si no, entonces no hay una UIImageView para ajustar la imagen en la celda.
                DispatchQueue.main.async {
                    if let strongSelf = self { // Comprobamos que la UIImageView exista ('self' es la imagen).
                        strongSelf.image = image
                    }
                }
            }
        })
        // 5.- LLamamos a 'resume()' para empezar.
        downloadTask.resume()
        // Depués devolvemos la URLSessionDownloadTask.
        // ¿Por qué devolverlo? Esto le da a la aplicación la
        // oportunidad de llamar a 'cancel()' en la tarea de descarga.
       
        return downloadTask
    }
}
