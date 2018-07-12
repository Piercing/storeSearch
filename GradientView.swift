//
//  GradientView.swift
//  StoreSearch
//
//  Created by Piercing on 27/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    // Nota 1: Por cierto, sólo se va a utilizar init (frame) para crear el ejemplo "GradientView".
    // El otro método init, "init? (coder)", nunca  se utiliza en  esta aplicación. "UIView" exige
    // que todas las subclases implementan init? (coder), es por eso que se marca como necesario y
    // si se quita este método, Xcode dará un error.
    
    // Sobreescribimos para establecer el color de fondo en ambos init.
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        // Esto le dice a la view que  debe cambiar tanto su anchura como su  altura proporcionalmente
        // cuanod la supervista va a ser redimensionada, debido a que se va a girar la app u otra cosa.
        // Esto significa que la vista GradientView siempre va a cubrir la misma área que cubren sus
        // super Views y no debe haber más huecos, incluso si el dispositivo se gira.
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // NOTA 2: Que en términos generales no es óptima para crear nuevos objetos en el interior de su método "draw()" , tal como
    // gradientes, especialmente si  "draw"()"  se llama a menudo. En ese caso, es mejor crear los objetos la primera vez que
    // los necesite y volver a utilizar la misma instancia  una y otra (lazy loading!). Pero aquí sólo se llama una sola vez.
    
    
    // Dibujamos el gradiente en la parte superior de este fondo transparente,
    // para que se funda con el fondo que esta debajo de él, utilizando el ---
    // framework Core Graphics, conocido como Quartz 2D, y esto es lo que hace:
    override func draw(_ rect: CGRect) {
        
        // 1.- Creamos dos matrices que contienen los "colors stop"
        // El primer color (0, 0, 0, 0,3) es de un color negro que es mayormente transparente. Se localiza en la posición 0
        // en el gradiente, que representa el centro de la pantalla, dado que vamos a crear un gradiente circular. El segundo
        // color (0, 0, 0, 0,7) también es de color negro, pero mucho menos transparente y se localiza en la posición --> 1,
        // representando la circunferencia del círculo gradiente. (Son valores fracionarios entre:  0,0 y 1,0 --> 0% a 100%)
        let components: [CGFloat]   = [0,0,0,0.3,0,0,0,0.7]
        let locations: [CGFloat]    = [0, 1]
        
        // 2.- Con los topes de colores podemos crear el gradiente. Esto nos da un nuvo objeto CGGradient.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2)
        
        // 3.- Ahora que tenemos el objeto gradiente, tenemos que averiguar qué tan grande necesitamos dibujarlo.
        // Las propiedades  "midX y midY" devuelven el punto central de un rectángulo. Este rectángulo viene dado
        // por límites, un objeto "CGRect"  que describe las diemensiones de la vista. La constante "centerPoint"
        // contiene las coordenadas para el punto central de la vista, y "radius" contiene los valores mayores de
        // "x" y de "y". "max()" es una función que se utiliza para determinar cuál de los dos valores es el mayor.
        let x = bounds.midX
        let y = bounds.midY
        let centerPoint = CGPoint(x: x, y: y)
        let radius = max(x, y)
        
        // 4.- Core Graphics siempre tiene lugar en un contexto gráfico, por tanto, lo necesitamos, para obtener una
        // referencia al contexto actual y entonces poder dibujar en él. Por último la función "drawRadialGradient()"
        // dibuja el gradiente de acuerdo a las especificaciones dadas.
        let context = UIGraphicsGetCurrentContext()
        context?.drawRadialGradient(gradient!, startCenter: centerPoint, startRadius: 0, endCenter: centerPoint, endRadius: radius, options: .drawsAfterEndLocation)
    }
}




























