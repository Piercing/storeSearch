//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Piercing on 28/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    // MARK: - Globals varialbes
    
    var search: Search!
    
    // Privada dado que sólo se utilizará en este controller
    // y  no fuera de él. No  debe de  ser visible por otros.
    // Controla la  primera vez que  accedemos a "LandScape".
    private var firstTime = true
    
    // Este array mantiene un registro de todos los objetos activos URLSessionDownloadTask
    private var downloadTasks = [URLSessionDownloadTask]()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // Para comprobar por consola que el objeto se ha
    // cancelado corret/ cuando la pantalla se cierra.
    // Además cancelamos todas las tareas que estén
    // ejecutándose al salir del modo landscape.
    deinit {
        print("deinit \(self)")
        for task in downloadTasks {
            task.cancel()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Como vamos a hacer nuestras propias restricciones y no las automáticas
        // que nos pone el Interface Builder ("IB")  eliminamos las "constrainsts"
        // actuales  en la view, en pageControl y en el "scroll View". La segunda
        // instrucción nos 2permite colocar y 2modificar el2 tamaño de las vistas
        // manualmente al poner dicha propiedad a "true", con esto no entramos en
        // conflicto con Auto Layout ya que para este controlador están activadas.
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        // Esto pone una imagen en el background del "scroll view", con lo que podemos ver que algo
        // está pasando cuando nos desplazamos a través de él.
        
        // ¿Una imagen? Pero estamos configurando la propiedad backgroundColor, que es un UIColor, no un UIImage.
        // Sí, eso  es cierto, pero UIColor tiene un truco  que nos permite usar un azulejo imagen para un color.
        
        // Si echamos un vistazo a la imagen "LandscapeBackground" en el catálogo de activos, podrás
        // ver que es un cuadrado pequeño. Al establecer esta imagen como una imagen de patrón en el
        // fondo, obtienemos una imagen repetible que llena toda la pantalla. Podemos  usar imágenes
        // tileable's en cualquier lugar donde podamos usar un UIColor.
        
        // UIImage (named) es un inicializador failable y por lo tanto devuelve un opcional.
        // Antes de que puedas usarlo  como un objeto UIImage real, necesitas desenvolverlo.
        // Aquí sabes que la imagen siempre existirá para que puedas desenvolverla con fuerza.
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        
        // Es importante cuando se trata de scroll views que se establezca la propiedad "contentSize".
        // Esto le dice al "scroll view" lo grande que debe de ser. No cambiamos el "frame (o el bounds)
        // del scroll viewsi deseamos que su interior sea más grande, en su lugar se establece esta propiedad.
        // A menudo se ovida este paso, y luego nos preguntamos por qué el scroll view no se desplaza. Por
        // desgracia no se puede establecer esta propiedad desde el Interface Builder, se hace por código.
        // scrollView.contentSize = CGSize(width: 1000, height: 1000) // --> !!Se puso sólo para probar que fuciona!!.
        
        
        // Activamos en el StoryBoard, en "scroll view" --> "Paging Enabled"
        // y añadimos aquí la siguient línea de código, para ocultar con eficacia
        // el "scroll view", para cuando no haya resultados en la búsqueda.
        pageControl.numberOfPages = 0
        
    }
    
    
    // El método "viewWillLayoutSubviews()"  es llamado por UIKit
    // como parte de la fase de diseño de su controlador de vista
    // cuando aparece por primera vez en la pantalla. Es el lugar
    // ideal para cambiar el frame  de sus puntos de vista a mano.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Nota: Recuerde que los "bounds" describen el rectángulo que conforma el interior de una vista,
        // mientras  que  los "frames" describen el exterior  de la  vista. El  "frame" del  "scrollView"
        // es  el rectángulo visto  desde la perspectiva de la vista  principal, mientras que el "bounds"
        // del "scrollVieww" es el mismo rectángulo del propio "scrollView".
        // Debido a que el -> "scrollView" y el -> "page control" son los dos hijos de la vista principal,
        // sus "frames" se sientan en la misma "coordinate space" como los "boounds" de la vista principal.
        
        
        // La vista de desplazamienteo siempre debe ser tan grande como toda la pantalla,
        // por lo que haremos su "frame" igual a los límites de la vista principal.
        scrollView.frame = view.bounds
        
        pageControl.frame = CGRect(x: 0, y: view.frame.size.height - pageControl.frame.size.height, width: view.frame.size.width, height: pageControl.frame.size.height)
        
        
        // Utilizamos esta variable para asegurarnos que sólo colocamos los buttons en landscape una sola vez.
        if firstTime {
            
            firstTime = false
            
            switch search.state {
                
                // Si hay resultados/objetos, los almacenamos en una variable
                // temporal, "list", y se los pasamos a "titleButtons", en los
                // demás casos, salimos.
            case .notSearchYet: break
            case .loading: showSpinner()
            case .noResults: showNothingFoundLabel()
            case .results(let list): titleButtons(list)
            }
        }
    }
    
    
    /* Aquí primero crea un objeto UILabel y le da texto y un color. Para hacer que la
     etiqueta se vea a través, la propiedad backgroundColor se establece en UIColor.clear.
     
     La llamada a "sizeToFit ()" le dice a la etiqueta que cambie el tamaño a un tamaño óptimo.
     Podríamos  darle a la  etiqueta un "frame" que sea lo suficientemente grande  para empezar,
     pero esto me parece mucho más fácil.(También ayuda cuando traduces la aplicación a un idioma
     diferente, en ese caso, es posible que no sepa de antemano qué tamaño debe tener la etiqueta.
     El único problema es que queremos centrar la etiqueta en la vista y como vimos antes, eso se
     complica cuando el ancho o la altura son impares (algo que no sabemos de antemano). Entonces
     aquí usamos un pequeño truco para forzar siempre las dimensiones de la etiqueta para que sean
     números pares: width = ceil (width / 2) * 2.
     
     Si divide un número como 11 por 2, obtiene 5.5. La función ceil () redondea 5.5 para hacer 6,
     y luego multiplicar por 2 para obtener un valor final de 12. Esta fórmula siempre le da el
     próximo número par si el original es impar. (Solo tienes que hacer esto porque estos valores
     tienen tipo CGFloat. Si fueran enteros, no tendríamos que preocuparnos por las partes fraccionarias).*/
    
    /* Nota: Porque no está usando un número codificado como 480 o 568, sino
     "scrollView.bounds" para determinar el ancho de la pantalla, el código
     para centrar la etiqueta funciona correctamente en todos los modelos de iPhone. */
    private func showNothingFoundLabel() {
        
        let label = UILabel(frame: CGRect.zero)
        label.text = "Nothing Found"
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.clear
        
        label.sizeToFit()
        
        var rect = label.frame
        rect.size.width = ceil(rect.size.width/2) * 2 // make even
        rect.size.height = ceil(rect.size.height/2) * 2 // make even
        label.frame = rect
        
        label.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
        view.addSubview(label)
    }
    
    // MARK: - Spinner
    
    /* Nota: Agregó 0.5 a la posición central del rotor. Este tipo de spinner es
     37 puntos de ancho y alto, que no es un número par. Si fueras a colocar el
     centro de esta vista en el centro exacto de la pantalla en (284, 160) luego
     extendería 18.5 puntos a cualquier extremo. La esquina superior izquierda de
     esa ruleta está en coordenadas (265.5, 141.5), lo que hace que parezca borroso.
     Lo mejor es evitar colocar objetos en coordenadas fraccionarias. Al agregar 0.5 a
     tanto la posición X como la Y, la ruleta se coloca en (266, 142) y todo
     se ve bien. Preste atención a esto cuando trabaje con la propiedad del centro y
     objetos que tienen anchuras o alturas impares. */
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.center = CGPoint(x: scrollView.bounds.midX + 0.5, y: scrollView.bounds.midY + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    // MARK: - LandScape methods
    
    // Primero, el método debe  decidir qué tan  grande serán los cuadrados de la cuadrícula y cuántos
    // cuadrados  necesita para llenar cada página. Hay cuatro casos a considerar, basados ​​en el ancho
    // de la pantalla:
    
    // • 480 puntos, dispositivo de 3,5 pulgadas  (se usa cuando ejecuta la aplicación en un iPad). Una sola
    // página se ajusta a 3 filas (rowsPerPage) de 5 columnas (columnsPerPage). Cada cuadrícula es 96 por 88
    // puntos (itemWidth y itemHeight). La primera fila comienza en Y = 20  (margenY).
    
    
    // • 568 puntos, dispositivo de 4 pulgadas (todos los modelos de iPhone 5, iPhone SE). Esto tiene 3 filas de 6
    // columnas Para que se ajuste, cada cuadrado de la cuadrícula ahora tiene solo 94 puntos de ancho. Porque 568
    // no se divide por 6, la variable de margenX se usa para ajustar por 4 puntos que quedan (2 en cada lado de la página).
    
    
    // • 667 puntos, dispositivo de 4.7 pulgadas  (iPhone 6, 6s, 7). Esto todavía  tiene 3 filas pero 7
    // columnas debido a que hay un poco de espacio vertical adicional, las filas son más altas (98 pts)
    // y hay un margen más grande en la parte superior.
    
    // • 736 puntos, dispositivo de 5,5 pulgadas (iPhone 6 / 6s / 7 Plus). Este dispositivo es enorme y
    // puede albergar 4 filas de 8 columnas.
    
    
    private func titleButtons(_ searchResults: [SearchResult]) {
        
        var columnsPerPage      = 5
        var rowsPerPage         = 3
        var itemWidth: CGFloat  = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat    = 0
        var marginY: CGFloat    = 20
        
        let buttonWidth: CGFloat    = 82
        let buttonHeight: CGFloat   = 82
        let paddingHorz             = (itemWidth - buttonWidth)/2
        let paddingVert             = (itemHeight - buttonHeight)/2
        let scrollViewWidth         = scrollView.bounds.size.width
        
        switch scrollViewWidth {
        case 568:
            columnsPerPage  = 6
            itemWidth       = 94
            marginX         = 2
            
        case 667:
            columnsPerPage  = 7
            itemWidth       = 95
            itemHeight      = 98
            marginX         = 1
            marginY         = 29
            
        case 736:
            columnsPerPage  = 8
            rowsPerPage     = 4
            itemWidth       = 92
            
        default:
            break
        }
        
        
        var row     = 0
        var column  = 0
        var x       = marginX
        
        for (_, searchResult) in searchResults.enumerated() {
            // 1.- Creamos el botón, utilizando el título con el índice del array.
            // Si hay 200 resultados de búsqueda, debemos terminar con 200 botones.
            // Personalizamos el boton, dándole una imagen de fonde en vez de título.
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            
            // Llamamos al método para descargar las imágenes 60x60 para agregarlas a los botones.
            downloadImage(for: searchResult, andPlaceOn: button)
            
            // 2.- Cuando se hace un botón por código, simpre hay que ajustar su frame.
            // Uitlizando las mediciones anteriores, se determina la posición y el tamaño.
            // Darse cuenta que los campos "CGRect" tienen todos tipo "CGFloat", pero la
            // fila (row) es de tipo "Int", ya que es necesario convertir una fila a CGFloat
            // antes de poder utilizarlo en el cálculo.
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row)*itemHeight + paddingVert,
                width: buttonWidth, height: buttonHeight)
            
            // 3.- Añadimos el nuevo botón a la subvista ScrollView. Después de los
            // primeros 18 botones (dependiendo del tamaño de la pantalla), se colocan
            // los siguientes botones fuera del rango visible de la "scroll view".
            // Configurando el scroll view consecuentemente con el contenido de la pantalla
            // el usuario podrá desplazarse para poder llegar a estos botones.
            scrollView.addSubview(button)
            
            // 4.- Utilizamos "X" y las varialbles "row" para colocar los botones, yendo de
            // arriba hacia abajo (mediante el aumento de "row"). Cuando hayamos llegado a
            // la parte inferior ("row" es igual a "rowsPerPage"), se sube de nuevo a "row"
            // a 0 y pasamos a la siguiente columna (mediane el aumento de la variable "column").
            // Cuando la columna alcanza el extremo de la pantalla (igual a "columnPerPage"), se
            // restable a 0 y añadimos cualquier espacio sobrante para "X" (el doble de X-margin).
            // Esto solo tiene efecto en las pantallas de 4 pulgadas y 4,7 pulgadas; para los demás
            // el margen "X" es 0.
            row += 1
            if row == rowsPerPage {
                row = 0; x += itemWidth; column += 1
                
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        
        // Aquí calculamos al "contentSize" para "scroll view" basado en el número de botones
        // que quepan en una página y el número de objetos de "SearchResult". Deseamos que el
        // usuario sea capaz de ir por las "páginas" de los resultados obtenidos, en lugar de
        // simplemente desplazarse, lo que siempre debe hacer que el contenido de anchura un
        // múltiplo de la anchura de pantalla (480, 568, 667 o 736 puntos).
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages)*scrollViewWidth,
            height: scrollView.bounds.size.height)
        print("Number of pages: \(numPages)")
        
        // Establecemos el número de puntos (dots) que  "page control"
        // mostrará según los cálculos que hicimos anteriormente.
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        
    }
    
    
    // En primer lugar se obtiene el objeto URL con el link para las imágenes 60x60 pixeles
    // y luego se crea una "task" de descarga. Dentro del "completion handler" se pone el
    // archivo descargado en una UIImage, y si la operación tuvo éxito, utilizamos el hilo
    // principal para colocar la imagen en los botones correspondientes.
    private func downloadImage(for searchResult: SearchResult, andPlaceOn button: UIButton) {
        
        if let url = URL(string: searchResult.artworkSmallURL) {
            // capturamos el button con un referencia débil (weak), para que cuando volteemos el teléfono
            // si existe aún una descarga, la referencia a el botón sea débil y coja el valor de nil para
            // que la aplicación no se caiga.
            let downloadTask = URLSession.shared.downloadTask(with: url) { [weak button] url, response, error in
                if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            }
            
            downloadTask.resume()
            
            downloadTasks.append(downloadTask)
        }
    }
    
    
    func searchResultsReceived() {
        
        hideSpinner()
        
        switch search.state {
        case .notSearchYet, .loading:
            break
        case .noResults:
            showNothingFoundLabel()
        case .results(let list):
            titleButtons(list)
        }
    }
    
    private func hideSpinner() {
        
        // "viewWithTag" puede devolver un nil de ahí el "?"
        view.viewWithTag(1000)?.removeFromSuperview()
    }
    
    
    // MARK: - Actions
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                        self.scrollView.contentOffset = CGPoint(x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0)
        }
            , completion: nil)
    }
}

// MARK: - Extensions

// Para que todo esto funcione, tenemos que hacer que el "scroll view" hable con "page control"
// y viceversa. El view controller debe ser el "delegado" de la "scroll view" por lo que será
// notificado cuando el usuario está ojeando las páginas.

// Este es uno de los métodos UIScrollViewDelegate.
// Averigüamos cual es el índice actual de la página mirando la propiedad "contentOffset" de la
// "scroll view". Esta propiedad determina hasta qué punto la "scroll view" se ha desplazado y
// se actuliza mientras se está arrastrando la "scroll view".

// Desafortunadamente, "scroll view" no nos dice simplemente,"El usuario ha volteado a la página
// X ", entonces debemos calcular esto nosotros mismos. Si la "content offset" va más allá de la
// mitad de la página (ancho / 2), la  "scroll view" se desplazará a la siguiente página. En eso
// actualiza el número de página activo de pageControl.

// Esto funciona a la inversa: cuando el usuario pulsa en el "Page Control", la propiedad "currentPage"
// se actualiza, utilizándose para calcular un nuevo "contentOffset" para la "scroll view".
extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pageControl.currentPage = currentPage
    }
}




























